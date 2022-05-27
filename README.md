# Rabbit hole

The general process for creating bindings with Clang.jl is as follows:
1. Create a `generator.jl` file with the relevant Julia code (not a lot).
2. Create a corresponding `generator.toml` file with certain settings.
3. Run `julia generator.jl` to create new file `LibP4est.jl`.
4. Apply manual fixes using `./fixes.sh`
5. Run `julia LibP4est.jl`.
6. Get error(s).
7. Try to finagle something with `generator.toml`, `prologue.jl`/`epilogue.jl`,
   or `fixes.sh`.
8. Go back to 3.
9. Despair.

## Types are missing
Need an `prologue.jl` file with
```julia
const ptrdiff_t = Cptrdiff_t
```

## Many functions and special macros that use C voodoo
Need to populate `output_ignorelist` for Clang generator.

## Many constants that refer to non-existent constants
Mostly `MPI_XXX`, e.g., `MPI_SUCCESS`, `MPI_COMM_WORLD` etc.
Add dummy definitions to `prologue.jl`, e.g.,
```julia
const MPI_SUCCESS = C_NULL
```

## Some p4est constants do not contain valid C code (but Fortran)
For example,
```c
#define P4EST_F90_LOCIDX INTEGER(KIND=C_INT32_T)
```
Need to write manual postprocessing script that removes offending lines from
`LibP4est.jl`: `./fixes.sh`

## Some p4est constants contain weird function definitions
Add entries like `P4EST_NOTICE` to remove list.


