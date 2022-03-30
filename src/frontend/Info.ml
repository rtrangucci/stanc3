open Core_kernel
open Ast
open Middle
open Yojson.Basic

let rec unsized_basetype_json t =
  let base_type_dims type_ dim : t =
    `Assoc [("type", `String type_); ("dimensions", `Int dim)] in
  match t with
  | UnsizedType.UInt -> base_type_dims "int" 0
  | UReal -> base_type_dims "real" 0
  | UComplex -> base_type_dims "complex" 0
  | UVector | URowVector -> base_type_dims "real" 1
  | UComplexVector | UComplexRowVector -> base_type_dims "complex" 1
  | UMatrix -> base_type_dims "real" 2
  | UComplexMatrix -> base_type_dims "complex" 2
  | UArray t' -> (
    match unsized_basetype_json t' with
    | `Assoc (ty :: ("dimensions", `Int dim) :: x) ->
        `Assoc (ty :: ("dimensions", `Int (dim + 1)) :: x)
    | _ ->
        Common.FatalError.fatal_error_msg
          [%message "Failed to produce info for type " (t : UnsizedType.t)] )
  | UMathLibraryFunction | UFun _ -> assert false

let basetype_dims t =
  match t with
  | Type.Sized t -> SizedType.to_unsized t |> unsized_basetype_json
  | Type.Unsized t -> unsized_basetype_json t

let get_var_decl {stmts; _} : t =
  `Assoc
    (List.fold_right ~init:[]
       ~f:(fun stmt acc ->
         match stmt.Ast.stmt with
         | Ast.VarDecl decl ->
             let type_info = basetype_dims decl.decl_type in
             (decl.identifier.name, type_info) :: acc
         | _ -> acc )
       stmts )

let block_info_json name block : t =
  `Assoc [(name, Option.value_map block ~default:(`Assoc []) ~f:get_var_decl)]

let rec get_function_calls_expr (funs, distrs) expr =
  let acc =
    match expr.expr with
    | FunApp (StanLib _, f, _) -> (Set.add funs f.name, distrs)
    | CondDistApp (StanLib _, f, _) -> (funs, Set.add distrs f.name)
    | _ -> (funs, distrs) in
  fold_expression get_function_calls_expr (fun acc _ -> acc) acc expr.expr

let rec get_function_calls_stmt ud_dists (funs, distrs) stmt =
  let acc =
    match stmt.stmt with
    | NRFunApp (StanLib _, f, _) -> (Set.add funs f.name, distrs)
    | Tilde {distribution; _} ->
        let possible_names =
          List.map ~f:(( ^ ) distribution.name) Utils.distribution_suffices
          |> String.Set.of_list in
        if List.exists ~f:(fun (n, _) -> Set.mem possible_names n) ud_dists then
          (funs, distrs)
        else
          let suffix =
            Stan_math_signatures.dist_name_suffix ud_dists distribution.name
          in
          let name = distribution.name ^ Utils.unnormalized_suffix suffix in
          (funs, Set.add distrs name)
    | _ -> (funs, distrs) in
  fold_statement get_function_calls_expr
    (get_function_calls_stmt ud_dists)
    (fun acc _ -> acc)
    (fun acc _ -> acc)
    acc stmt.stmt

let function_calls_json p =
  let map f list_op =
    Option.value_map ~default:[]
      ~f:(fun {stmts; _} -> List.concat_map ~f stmts)
      list_op in
  let grab_fundef_names_and_types = function
    | {Ast.stmt= Ast.FunDef {funname; arguments= (_, type_, _) :: _; _}; _} ->
        [(funname.name, type_)]
    | _ -> [] in
  let ud_dists = map grab_fundef_names_and_types p.functionblock in
  let funs, distrs =
    fold_program
      (get_function_calls_stmt ud_dists)
      (String.Set.empty, String.Set.empty)
      p in
  let set_to_List s =
    `List (Set.to_list s |> List.map ~f:(fun str -> `String str)) in
  `Assoc [("functions", set_to_List funs); ("distributions", set_to_List distrs)]

let includes_json () =
  `Assoc
    [ ( "included_files"
      , `List
          ( List.rev !Preprocessor.included_files
          |> List.map ~f:(fun str -> `String str) ) ) ]

let info_json ast =
  List.fold ~f:Util.combine ~init:(`Assoc [])
    [ block_info_json "inputs" ast.datablock
    ; block_info_json "parameters" ast.parametersblock
    ; block_info_json "transformed parameters" ast.transformedparametersblock
    ; block_info_json "generated quantities" ast.generatedquantitiesblock
    ; function_calls_json ast; includes_json () ]

let info ast = pretty_to_string (info_json ast)
