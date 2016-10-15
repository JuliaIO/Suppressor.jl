using Suppressor
using Base.Test

output = @capture_out begin
    println("should get captured, not printed")
end
@test output == "should get captured, not printed\n"

output = @capture_err begin
    warn("should get captured, not printed")
end
@test output == "\e[1m\e[31mWARNING: should get captured, not printed\e[0m\n"

@suppress begin
    println("This string doesn't get printed!")
    warn("This warning is ignored.")
end

@suppress_out begin
    println("This string doesn't get printed!")
    warn("This warning is important")
end
# WARNING: This warning is important

@suppress_err begin
    println("This string gets printed!")
    warn("This warning is unimportant")
end
# This string gets printed!

@test_throws ErrorException @suppress begin
    println("This string doesn't get printed!")
    warn("This warning is ignored.")
    error("Remember that errors are still printed!")
end
#=
------------------------------------------------------------------------------------------
ErrorException                                          Stacktrace (most recent call last)
[#2] — anonymous
       ⌙ at <missing>:?

[#1] — macro expansion;
       ⌙ at Suppressor.jl:16 [inlined]

Remember that errors are still printed!
=#
