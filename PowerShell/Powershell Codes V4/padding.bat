rem Delayed environment variable expansion is needed for loop solutions.
setlocal EnableDelayedExpansion

for /L %%I in (0,1,350) do (
    set "Value=00%%I"
    echo Value is !Value:~-3!
)