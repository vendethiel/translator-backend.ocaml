open Ppx_yojson_conv_lib.Yojson_conv.Primitives

let routes =
  [
    Dream.get "/projects" (fun request ->
        let%lwt projects = Dream.sql request Project_object.list in
        projects
        |> yojson_of_list Project_object.yojson_of_t
        |> Yojson.Safe.to_string |> Dream.json);
    Dream.get "/projects/:id" (fun request ->
        let id_param = Dream.param request "id" in
        match int_of_string_opt id_param with
        | None -> Dream.empty `Bad_Request
        | Some id ->
            let%lwt project = Dream.sql request (Project_object.find id) in
            project |> Project_object.yojson_of_t |> Yojson.Safe.to_string
            |> Dream.json);
    (* TODO *)
    Dream.post "/projects" (fun request ->
        let%lwt body = Dream.body request in
        let project_api =
          body |> Yojson.Safe.from_string |> Project_api.t_of_yojson
        in
        project_api |> Project_api.to_object 0 |> Project_object.yojson_of_t
        |> Yojson.Safe.to_string |> Dream.json);
  ]
