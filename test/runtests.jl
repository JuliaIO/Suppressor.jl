using Suppressor
using Base.Test

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
