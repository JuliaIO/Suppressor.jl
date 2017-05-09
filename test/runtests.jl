using Suppressor
using Base.Test

# make sure color is off to simplify testing for output
eval(Base, :(have_color = false))

output = @capture_out begin
    println("should get captured, not printed")
end
@test output == "should get captured, not printed\n"

output = @capture_err begin
    warn("should get captured, not printed")
end
@test output == "WARNING: should get captured, not printed\n"

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

# test that the macros work inside a function
function f1()
    @suppress println("should not get printed")
    42
end

@test f1() == 42

function f2()
    @suppress_out println("should not get printed")
    42
end

@test f2() == 42

function f3()
    @suppress_err println("should not get printed")
    42
end

@test f3() == 42

function f4()
    @capture_out println("should not get printed")
    42
end

@test f4() == 42

function f5()
    @capture_err println("should not get printed")
    42
end

@test f4() == 42
