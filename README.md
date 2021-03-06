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

If you want to try this yourself using this repo, set up all dependencies using
```shell
julia --project -e 'using Pkg; Pkg.instantiate()'
```
This is only required once.

To generate new bindings, run
```shell
julia --project generator.jl && ./fixes.sh
```
to create a new `LibP4est.jl` file. If you did not get an error yet - 🥳🕺

Next, try if it actually works by running the following smoke test after
starting the REPL with `julia --project`:
```julia
julia> include("LibP4est.jl")
Main.LibP4est

julia> using .LibP4est

julia> (p4est_version_major(), p4est_version_minor()) == (2, 8)
true
```

Finally, try to repeat the example from
[P4est.jl](https://github.com/trixi-framework/P4est.jl#usage), albeit with a
slightly modified syntax:
```julia
julia> include("LibP4est.jl")
Main.LibP4est

julia> using .LibP4est, MPI

julia> MPI.Init()
THREAD_SERIALIZED::ThreadLevel = 2

julia> conn_ptr = p4est_connectivity_new_periodic()
Ptr{p4est_connectivity} @0x0000000002698e10

julia> p4est_connectivity_is_valid(conn_ptr)
1

julia> p4est_ptr = p4est_new_ext(MPI.COMM_WORLD, conn_ptr, 0, 2, 0, 0, C_NULL, C_NULL)
Into p4est_new with min quadrants 0 level 2 uniform 0
New p4est with 1 trees on 1 processors
Initial level 2 potential global quadrants 16 per tree 16
Done p4est_new with 10 total quadrants
Ptr{Main.LibP4est.p4est} @0x00000000025a4f50

julia> p4est_ = unsafe_wrap(Array, p4est_ptr, 1)
1-element Vector{Main.LibP4est.p4est}:
 Main.LibP4est.p4est(1140850688, 1, 0, 0, 0x0000000000000000, Ptr{Nothing} @0x0000000000000000, 0, 0, 0, 10, 10, Ptr{Int64} @0x000000000262a3c0, Ptr{p4est_quadrant} @0x0000000002483f80, Ptr{p4est_connectivity} @0x0000000002698e10, Ptr{sc_array} @0x0000000001d04770, Ptr{sc_mempool} @0x0000000000000000, Ptr{sc_mempool} @0x00000000025a5a10, Ptr{p4est_inspect} @0x0000000000000000)

julia> p4est_[1].connectivity == conn_ptr
true

julia> conn_ = unsafe_wrap(Array, p4est_[1].connectivity, 1)
1-element Vector{p4est_connectivity}:
 p4est_connectivity(4, 1, 1, Ptr{Float64} @0x0000000002585c50, Ptr{Int32} @0x0000000002585460, 0x0000000000000000, Cstring(0x0000000000000000), Ptr{Int32} @0x000000000253d350, Ptr{Int8} @0x00000000026e12f0, Ptr{Int32} @0x00000000026919b0, Ptr{Int32} @0x00000000024aa340, Ptr{Int32} @0x00000000023d2e40, Ptr{Int8} @0x00000000024cdf60)

julia> conn_[1].num_trees
1
```

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

## Some MPI types are erroneously deleted where it would be bad
Replace, e.g. `mpicomm::Cint` by `mpicomm::MPI_Comm`.

## Startup latency compared to CBinding.jl-generated bindings
On Rocinante, we get for the CBinding.jl-generated bindings
```shell
julia --project -e '@time begin include("libp4est-wrap.jl"); using .LibP4est end'
 12.345134 seconds (32.51 M allocations: 1.767 GiB, 2.72% gc time, 83.41% compilation time)
```
For the Clang.jl-generated bindings in this repo, we get
```shell
julia --project -e '@time begin include("LibP4est.jl"); using .LibP4est end'
  1.544455 seconds (1.18 M allocations: 65.286 MiB, 0.49% gc time, 21.00% compilation time)
```
Thus, using the less convenient Clang.jl-generated binaries *considerably*
reduces startup latency (1.5 seconds instead of 12.3 seconds) and memory use (65 MiB vs. 1,767 MiB)

However, note that this measures basically the precompilation time. To work
with precompiled code, you need to put it in packages. Here, we created
subfolders `P4estViaCBinding0` for the approach using CBinding.jl v0.9 and
`P4estViaClang` for the approach using Clang.jl. Then, we get (on another
system)
```shell
julia --project=P4estViaCBinding0 -e '@time @eval using P4estViaCBinding0'
  7.707895 seconds (361.77 k allocations: 26.919 MiB, 0.44% compilation time)

julia --project=P4estViaCBinding0 -e '@time @eval using P4estViaCBinding0'
  0.133317 seconds (333.90 k allocations: 25.119 MiB, 17.93% compilation time)
```
and
```shell
julia --project=P4estViaClang -e '@time @eval using P4estViaClang'
  1.442068 seconds (141.51 k allocations: 12.155 MiB, 2.35% compilation time)

julia --project=P4estViaClang -e '@time @eval using P4estViaClang'
  0.068284 seconds (113.65 k allocations: 10.355 MiB, 35.38% compilation time)
```
The first result each includes precompilation, the second one doesn't.

We can also use the same approach with CBinding.jl v1:
```shell
julia --project=P4estViaCBinding1 -e '@time @eval using P4estViaCBinding1'
┌ Warning: Failed to find `sc_memory_check_noerr` in:
│   ~/.julia/artifacts/0a2d5cebfd9e9b6072a1283ba38086a7e8211f37/lib/libp4est
│   or the Julia process
└ @ CBinding ~/.julia/packages/CBinding/U3ykW/src/context.jl:48
  6.922208 seconds (454.20 k allocations: 32.493 MiB, 0.50% compilation time)

julia --project=P4estViaCBinding1 -e '@time @eval using P4estViaCBinding1'
  0.169842 seconds (426.02 k allocations: 30.664 MiB, 14.36% compilation time)
```
