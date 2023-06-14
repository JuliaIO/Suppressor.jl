__precompile__()

module Suppressor

using Logging
export @suppress, @suppress_out, @suppress_err
export @capture_out, @capture_err
export @color_output

"""
    @suppress expr

Suppress the `stdout` and `stderr` streams for the given expression.
"""
macro suppress(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            original_stdout = stdout
            out_rd, out_wr = redirect_stdout()
            out_reader = @async read(out_rd, String)

            original_stderr = stderr
            err_rd, err_wr = redirect_stderr()
            err_reader = @async read(err_rd, String)

            # approach adapted from https://github.com/JuliaLang/IJulia.jl/pull/667/files
            logstate = Base.CoreLogging._global_logstate
            logger = logstate.logger
            if :stream in propertynames(logger) && logger.stream == original_stderr
                _logger = typeof(logger)(err_wr, logger.min_level)
                new_logstate = Base.CoreLogging.LogState(_logger)
                Core.eval(Base.CoreLogging, Expr(:(=), :(_global_logstate), new_logstate))
            else
                _logger = logger
            end
        end

        try
            Logging.with_logger(_logger) do
                $(esc(block))
            end
        finally
            if ccall(:jl_generating_output, Cint, ()) == 0
                redirect_stdout(original_stdout)
                close(out_wr)

                redirect_stderr(original_stderr)
                close(err_wr)

                if :stream in propertynames(logger) && logger.stream == stderr
                    Core.eval(Base.CoreLogging, Expr(:(=), :(_global_logstate), logstate))
                end
            end
        end
    end
end

"""
    @suppress_out expr

Suppress the `stdout` stream for the given expression.
"""
macro suppress_out(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            original_stdout = stdout
            out_rd, out_wr = redirect_stdout()
            out_reader = @async read(out_rd, String)
        end

        try
            $(esc(block))
        finally
            if ccall(:jl_generating_output, Cint, ()) == 0
                redirect_stdout(original_stdout)
                close(out_wr)
            end
        end
    end
end

"""
    @suppress_err expr

Suppress the `stderr` stream for the given expression.
"""
macro suppress_err(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            original_stderr = stderr
            err_rd, err_wr = redirect_stderr()
            err_reader = @async read(err_rd, String)

            # approach adapted from https://github.com/JuliaLang/IJulia.jl/pull/667/files
            logstate = Base.CoreLogging._global_logstate
            logger = logstate.logger
            if :stream in propertynames(logger) && logger.stream == original_stderr
                _logger = typeof(logger)(err_wr, logger.min_level)
                new_logstate = Base.CoreLogging.LogState(_logger)
                Core.eval(Base.CoreLogging, Expr(:(=), :(_global_logstate), new_logstate))
            else
                _logger = logger
            end
        end

        try
            Logging.with_logger(_logger) do
                $(esc(block))
            end
        finally
            if ccall(:jl_generating_output, Cint, ()) == 0
                redirect_stderr(original_stderr)
                close(err_wr)

                if :stream in propertynames(logger) && logger.stream == stderr
                    Core.eval(Base.CoreLogging, Expr(:(=), :(_global_logstate), logstate))
                end
            end
        end
    end
end


"""
    @capture_out expr

Capture the `stdout` stream for the given expression.
"""
macro capture_out(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            original_stdout = stdout
            out_rd, out_wr = redirect_stdout()
            out_reader = @async read(out_rd, String)
        end

        try
            $(esc(block))
        finally
            if ccall(:jl_generating_output, Cint, ()) == 0
                redirect_stdout(original_stdout)
                close(out_wr)
            end
        end

        if ccall(:jl_generating_output, Cint, ()) == 0
            fetch(out_reader)
        else
            ""
        end
    end
end

"""
    @capture_err expr

Capture the `stderr` stream for the given expression.
"""
macro capture_err(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            original_stderr = stderr
            err_rd, err_wr = redirect_stderr()
            err_reader = @async read(err_rd, String)

            # approach adapted from https://github.com/JuliaLang/IJulia.jl/pull/667/files
            logstate = Base.CoreLogging._global_logstate
            logger = logstate.logger
            if :stream in propertynames(logger) && logger.stream == original_stderr
                _logger = typeof(logger)(err_wr, logger.min_level)
                new_logstate = Base.CoreLogging.LogState(_logger)
                Core.eval(Base.CoreLogging, Expr(:(=), :(_global_logstate), new_logstate))
            else
                _logger = logger
            end
        end

        try
            Logging.with_logger(_logger) do
                $(esc(block))
            end
        finally
            if ccall(:jl_generating_output, Cint, ()) == 0
                redirect_stderr(original_stderr)
                close(err_wr)

                if :stream in propertynames(logger) && logger.stream == stderr
                    Core.eval(Base.CoreLogging, Expr(:(=), :(_global_logstate), logstate))
                end
            end
        end

        if ccall(:jl_generating_output, Cint, ()) == 0
            fetch(err_reader)
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
