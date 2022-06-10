# P4estViaCBinding1

An experimental package setup using CBinding.jl v1 to generate bindings
of P4est_jll.jl. Smoke test
```julia
julia> using MPI, P4estViaCBinding1

julia> MPI.Init()
THREAD_SERIALIZED::ThreadLevel = 2

julia> conn_ptr = p4est_connectivity_new_periodic()
CBinding.Cptr{var"c\"struct p4est_connectivity\""}(0x0000000001eee870)

julia> p4est_connectivity_is_valid(conn_ptr)
1

julia> p4est_ptr = p4est_new_ext(MPI.COMM_WORLD, conn_ptr, 0, 2, 0, 0, C_NULL, C_NULL)
Into p4est_new with min quadrants 0 level 2 uniform 0
New p4est with 1 trees on 1 processors
Initial level 2 potential global quadrants 16 per tree 16
Done p4est_new with 10 total quadrants
CBinding.Cptr{var"c\"struct p4est\""}(0x00000000026ab920)

julia> p4est_ptr.connectivity
CBinding.Cptr{CBinding.Cptr{var"c\"struct p4est_connectivity\""}}(0x00000000026ab970)

julia> p4est_ptr.connectivity.num_trees
CBinding.Cptr{Int32}(0x0000000001eee874)

julia> unsafe_load(p4est_ptr.connectivity.num_trees)
1
```
