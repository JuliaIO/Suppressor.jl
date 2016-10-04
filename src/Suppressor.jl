__precompile__()

module Suppressor

export @suppress, @suppress_out, @suppress_err

macro suppress(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDOUT = STDOUT
            out_rd, out_wr = redirect_stdout()
            out_reader = @async readstring(out_rd)

            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @async readstring(err_rd)

            value = $(esc(block))

            @async wait(out_reader)
            REDIRECTED_STDOUT = STDOUT
            out_stream =redirect_stdout(ORIGINAL_STDOUT)

            @async wait(err_reader)
            REDIRECTED_STDERR = STDERR
            err_stream = redirect_stderr(ORIGINAL_STDERR)

            return value
        end
    end
end

macro suppress_out(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDOUT = STDOUT
            out_rd, out_wr = redirect_stdout()
            out_reader = @async readstring(out_rd)

            value = $(esc(block))

            @async wait(out_reader)
            REDIRECTED_STDOUT = STDOUT
            out_stream = redirect_stdout(ORIGINAL_STDOUT)

            return value
        end
    end
end

macro suppress_err(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @async readstring(err_rd)

            value = $(esc(block))

            @async wait(err_reader)
            REDIRECTED_STDERR = STDERR
            err_stream = redirect_stderr(ORIGINAL_STDERR)

            return value
        end
    end
end

end    # module
