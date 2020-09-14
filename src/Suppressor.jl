__precompile__()

module Suppressor
using Logging

export @suppress, @suppress_out, @suppress_err
export @capture, @capture_out, @capture_err
export @color_output

"""
   jl_not_compiling()

Check if julia is not in one of its compilation stages set by one of the 
flags "--output-bc", "--output-unopt-bc", "--output-o",	"--output-asm",	 "--output-ji",	 "--output-incremental",
where it would output some transformed version of the code instead of executing it.
"""
jl_not_compiling()=ccall(:jl_generating_output, Cint, ())==0


"""
    @suppress_out block

Suppress the `stdout` stream for the given blockession.
"""
macro suppress_out(block)
    quote
        if jl_not_compiling()
            original_stdout = stdout
            out_rd, out_wr = redirect_stdout()
            out_reader = @async read(out_rd, String)
        end
        try
            $(esc(block))
        finally
            if jl_not_compiling()
                redirect_stdout(original_stdout)
                close(out_wr)
            end
        end
    end
end

"""
    @suppress_err block

Suppress the `stderr` stream for the given blockession.
"""
macro suppress_err(block)
    quote
        if jl_not_compiling()
            original_stderr = stderr
            err_rd, err_wr = redirect_stderr()
            err_reader = @async read(err_rd, String)
            logger=NullLogger()
        else
            logger=current_logger()
        end
        try
	    with_logger(logger) do	
                $(esc(block))
            end
        finally
            if jl_not_compiling()
                redirect_stderr(original_stderr)
                close(err_wr)
            end
        end
    end
end

"""
    @suppress block

   Suppress the `stdout` and `stderr` streams for the given blockession.
    """
macro suppress(block)
    quote
        if jl_not_compiling()
            original_stdout = stdout
            out_rd, out_wr = redirect_stdout()
            reader = @async read(out_rd)
            logger=NullLogger()
        else
            logger=current_logger()
        end
        try
	    with_logger(logger) do	
	        redirect_stderr(()->$(esc(block)),stdout)
	    end
        finally
            if jl_not_compiling()
	        redirect_stdout(original_stdout)
                close(out_wr)
            end
        end
    end
end


"""
    @capture_out block

Capture the `stdout` stream for the given blockession.
"""
macro capture_out(block)
    quote
        if jl_not_compiling()
            original_stdout = stdout
            out_rd, out_wr = redirect_stdout()
            out_reader = @async read(out_rd, String)
        end
        try
            $(esc(block))
        finally
            if jl_not_compiling()
                redirect_stdout(original_stdout)
                close(out_wr)
            end
        end
        if jl_not_compiling()
            fetch(out_reader)
        else
            ""
        end
    end
end

"""
     @capture_err block
     Capture the `stderr` stream for the given blockession.
"""
macro capture_err(block)
    quote
        if jl_not_compiling()
            original_stderr = stderr
            err_rd, err_wr = redirect_stderr()
            err_reader = @async read(err_rd, String)
            logger=ConsoleLogger(stderr)
        else
            logger=current_logger()
        end
        try
	    with_logger(logger) do	
                $(esc(block))
            end
        finally
            if jl_not_compiling()
                redirect_stderr(original_stderr)
                close(err_wr)
            end
        end
        if jl_not_compiling()
            fetch(err_reader)
        else
            ""
        end
    end
end

"""
    @capture block

Capture the `output` and `stderr` streams for the given blockession,
return a string containing output from both
"""
macro capture(block)
    quote
        if jl_not_compiling()
            original_stdout = stdout
            out_rd, out_wr = redirect_stdout()
            reader = @async read(out_rd, String)
            logger=ConsoleLogger(stdout)
        else
            logger=current_logger()
        end
        try
	    with_logger(logger) do	
	        redirect_stderr(()->$(esc(block)),stdout)
	    end
        finally
            if jl_not_compiling()
	        redirect_stdout(original_stdout)
                close(out_wr)
            end
        end

        if jl_not_compiling()
            fetch(reader)
        else
            ""
        end
    end
end


"""
    @color_output enabled::Bool block

Enable or disable color printing for the given blockession. Often useful in
combination with the `@capture_*` macros:

## Example

@color_output false begin
    output = @capture_err begin
        @warn "should get captured, not printed"
    end
end
@test output == "WARNING: should get captured, not printed\n"
"""
macro color_output(enabled::Bool, block)
    quote
        prev_color = Base.have_color
        Core.eval(Base, :(have_color = $$enabled))
        local retval
        try
            retval = $(esc(block))
        finally
            Core.eval(Base, Expr(:(=), :have_color, prev_color))
        end

        retval
    end
end

end    # module
