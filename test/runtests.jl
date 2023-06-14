using Base: @info, printstyled, stderr, stdout
using Logging: ConsoleLogger, with_logger
using Suppressor
using Test: @testset, @test, @test_throws

@testset "Suppressor" begin

# everything that prints to stdout and stderr should be prefixed with an
# incrementing number so we can check that the output is as expected

@testset "stdout capture" begin
    output = @capture_out begin
        println("CAPTURED STDOUT")
        println(stderr, "01 PRINTED STDERR")
    end
    @test output == "CAPTURED STDOUT\n"
    println("02 PRINTED STDOUT")
end

@testset "stderr capture" begin
    output = @capture_err begin
        println("03 PRINTED STDOUT")
        println(stderr, "CAPTURED STDERR")
    end
    @test output == "CAPTURED STDERR\n"
    println(stderr, "04 PRINTED STDERR")
end

# we're assuming the global context here has color enabled
@testset "disabling color" begin
    printstyled("05 PRINTED GREEN STDOUT\n", color=:green)
    printstyled(stderr, "06 PRINTED GREEN STDERR\n", color=:green)

    @color_output false begin
        printstyled("07 PRINTED NORMAL STDOUT\n", color=:green)
        printstyled(stderr, "08 PRINTED NORMAL STDERR\n", color=:green)
    end

    printstyled("09 PRINTED GREEN STDOUT\n", color=:green)
    printstyled(stderr, "10 PRINTED GREEN STDERR\n", color=:green)
end

@testset "enabling color" begin
    @color_output false begin
        printstyled("11 PRINTED NORMAL STDOUT\n", color=:green)
        printstyled(stderr, "12 PRINTED NORMAL STDERR\n", color=:green)

        @color_output true begin
            printstyled("13 PRINTED GREEN STDOUT\n", color=:green)
            printstyled(stderr, "14 PRINTED GREEN STDERR\n", color=:green)
        end

        printstyled("15 PRINTED NORMAL STDOUT\n", color=:green)
        printstyled(stderr, "16 PRINTED NORMAL STDERR\n", color=:green)
    end
end

@testset "stdout suppression" begin
    @test @suppress_out begin
        println("SUPPRESSED STDOUT")
        println(stderr, "17 PRINTED STDERR")
        42
    end == 42
    println("18 PRINTED STDOUT")
end

@testset "stderr suppression" begin
    @test @suppress_err begin
        println("19 PRINTED STDOUT")
        println(stderr, "SUPPRESSED STDERR")
        42
    end == 42
    println(stderr, "20 PRINTED STDERR")
end

@testset "stderr and stdout suppression" begin
    @test @suppress begin
        println("SUPPRESSED STDOUT")
        println(stderr, "SUPPRESSED STDERR")
        42
    end == 42
    println("21 PRINTED STDOUT")
    println(stderr, "22 PRINTED STDERR")
end

# make sure that things still work after an exception is thrown
@testset "exception cleanup" begin
    try
        @capture_out throw(ErrorException(""))
    catch
    end
    println("23 PRINTED STDOUT")
    println(stderr, "24 PRINTED STDERR")

    try
        @capture_err throw(ErrorException(""))
    catch
    end
    println("25 PRINTED STDOUT")
    println(stderr, "26 PRINTED STDERR")

    try
        @suppress throw(ErrorException(""))
    catch
    end
    println("27 PRINTED STDOUT")
    println(stderr, "28 PRINTED STDERR")

    try
        @suppress_out throw(ErrorException(""))
    catch
    end
    println("29 PRINTED STDOUT")
    println(stderr, "30 PRINTED STDERR")

    try
        @suppress_err throw(ErrorException(""))
    catch
    end
    println("31 PRINTED STDOUT")
    println(stderr, "32 PRINTED STDERR")
end

@test_throws ErrorException @suppress begin
    println("SUPPRESSED STDOUT")
    println(stderr, "SUPPRESSED STDERR")
    error("errors would normally get printed but are caught here by @test_throws")
end

@testset "logging capture" begin
    output = @capture_err @info "CAPTURED LOGINFO"
    # 0.6.2 output:
    if isdefined(Base, :CoreLogging)
        @test output == "[ Info: CAPTURED LOGINFO\n"
    else
        @test output == "\e[1m\e[36mInfo: \e[39m\e[22m\e[36mCAPTURED LOGINFO\n\e[39m"
    end
    @info "33 PRINTED LOGINFO"
end

@testset "logging suppression" begin
    @suppress_err @info "SUPPRESSED LOGINFO"
    @info "34 PRINTED LOGINFO"

    @suppress @info "SUPPRESSED LOGINFO"
    @info "35 PRINTED LOGINFO"
end

@testset "color output exception handling" begin
    @color_output true begin
        try
            @color_output false begin
                throw(Exception())
            end
        catch
        end
        printstyled("36 PRINTED GREEN STDOUT\n", color=:green)
        printstyled("37 PRINTED GREEN STDERR\n", color=:green)
    end
end

@testset "capture_err within with_logger" begin
    out = with_logger(ConsoleLogger(stderr)) do;
        @capture_err begin
            @error "@error"
        end
    end
    @test startswith(out, "┌ Error: @error")
end

@testset "suppress_err within with_logger" begin
    mktemp() do path, io
        redirect_stderr(io) do
            with_logger(ConsoleLogger(stderr)) do
                @suppress_err begin
                    @error "@error"
                end
            end
        end
        flush(io)
        @test read(path, String) == ""
    end
end

@testset "suppress within with_logger" begin
    mktemp() do path, io
        redirect_stderr(io) do
            with_logger(ConsoleLogger(stderr)) do
                @suppress begin
                    @error "@error"
                end
            end
        end
        flush(io)
        @test read(path, String) == ""
    end
end

end # @testset "Suppressor"
