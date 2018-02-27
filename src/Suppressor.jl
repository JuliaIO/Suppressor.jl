__precompile__()

module Suppressor
using Compat

export @suppress, @suppress_out, @suppress_err
export @capture_out, @capture_err
export @color_output


_jl_generating_output() = ccall(:jl_generating_output, Cint, ()) == 0 ? false : true

"""
    @suppress expr

Suppress the STDOUT and STDERR streams for the given expression.
"""
macro suppress(block)
    quote
        if !_jl_generating_output()
            ORIGINAL_STDOUT = STDOUT
            out_rd, out_wr = redirect_stdout()
            out_reader = @schedule read(out_rd, String)

            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @schedule read(err_rd, String)
        end

        try
            $(esc(block))
        finally
            if !_jl_generating_output()
                redirect_stdout(ORIGINAL_STDOUT)
                close(out_wr)

                redirect_stderr(ORIGINAL_STDERR)
                close(err_wr)
            end
        end
    end
end

"""
    @suppress_out expr

Suppress the STDOUT stream for the given expression.
"""
macro suppress_out(block)
    quote
        if !_jl_generating_output()
            ORIGINAL_STDOUT = STDOUT
            out_rd, out_wr = redirect_stdout()
            out_reader = @schedule read(out_rd, String)
        end

        try
            $(esc(block))
        finally
            if !_jl_generating_output()
                redirect_stdout(ORIGINAL_STDOUT)
                close(out_wr)
            end
        end
    end
end

"""
    @suppress_err expr

Suppress the STDERR stream for the given expression.
"""
macro suppress_err(block)
    quote
        if !_jl_generating_output()
            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @schedule read(err_rd, String)
        end

        try
            $(esc(block))
        finally
            if !_jl_generating_output()
                redirect_stderr(ORIGINAL_STDERR)
                close(err_wr)
            end
        end
    end
end


"""
    @capture_out expr

Capture the STDOUT stream for the given expression.
"""
macro capture_out(block)
    quote
        if !_jl_generating_output()
            ORIGINAL_STDOUT = STDOUT
            out_rd, out_wr = redirect_stdout()
            out_reader = @schedule read(out_rd, String)
        end

        try
            $(esc(block))
        finally
            if !_jl_generating_output()
                redirect_stdout(ORIGINAL_STDOUT)
                close(out_wr)
            end
        end

        if !_jl_generating_output()
            wait(out_reader)
        else
            ""
        end
    end
end

"""
    @capture_err expr

Capture the STDERR stream for the given expression.
"""
macro capture_err(block)
    quote
        if !_jl_generating_output()
            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @schedule read(err_rd, String)
        end

        try
            $(esc(block))
        finally
            if !_jl_generating_output()
                redirect_stderr(ORIGINAL_STDERR)
                close(err_wr)
            end
        end

        if !_jl_generating_output()
            wait(err_reader)
        else
            ""
        end
    end
end

"""
    @color_output enabled::Bool expr

Enable or disable color printing for the given expression. Often useful in
combination with the `@capture_*` macros:

## Example

@color_output false begin
    output = @capture_err begin
        warn("should get captured, not printed")
    end
end
@test output == "WARNING: should get captured, not printed\n"
"""
macro color_output(enabled::Bool, block)
    quote
        prev_color = Base.have_color
        eval(Base, :(have_color = $$enabled))
        retval = $(esc(block))
        eval(Base, Expr(:(=), :have_color, prev_color))

        retval
    end
end

end    # module
