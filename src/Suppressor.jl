__precompile__()

module Suppressor
using Compat

export @suppress, @suppress_out, @suppress_err
export @capture_out, @capture_err

macro suppress(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDOUT = STDOUT
            out_rd, out_wr = redirect_stdout()
            out_reader = @async read(out_rd, String)

            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @async read(err_rd, String)
        end

        value = $(esc(block))

        if ccall(:jl_generating_output, Cint, ()) == 0
            redirect_stdout(ORIGINAL_STDOUT)
            close(out_wr)

            redirect_stderr(ORIGINAL_STDERR)
            close(err_wr)
        end
        value
    end
end

macro suppress_out(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDOUT = STDOUT
            out_rd, out_wr = redirect_stdout()
            out_reader = @async read(out_rd, String)
        end

        value = $(esc(block))

        if ccall(:jl_generating_output, Cint, ()) == 0
            redirect_stdout(ORIGINAL_STDOUT)
            close(out_wr)
        end
        value
    end
end

macro suppress_err(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @async read(err_rd, String)
        end

        value = $(esc(block))

        if ccall(:jl_generating_output, Cint, ()) == 0
            redirect_stderr(ORIGINAL_STDERR)
            close(err_wr)
        end
        value
    end
end

macro capture_out(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDOUT = STDOUT
            out_rd, out_wr = redirect_stdout()
            out_reader = @async read(out_rd, String)
        end

        $(esc(block))

        if ccall(:jl_generating_output, Cint, ()) == 0
            redirect_stdout(ORIGINAL_STDOUT)
            close(out_wr)

            wait(out_reader)
        else
            ""
        end
    end
end

macro capture_err(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @async read(err_rd, String)
        end

        $(esc(block))

        if ccall(:jl_generating_output, Cint, ()) == 0
            redirect_stderr(ORIGINAL_STDERR)
            close(err_wr)

            wait(err_reader)
        else
            ""
        end
    end
end

end    # module
