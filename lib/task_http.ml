open Ppx_yojson_conv_lib.Yojson_conv.Primitives

let routes =
  [
    Dream.get "/projects/:project_id/tasks" (fun request ->
        let project_id_param = Dream.param request "project_id" in
        match int_of_string_opt project_id_param with
        | None -> Dream.empty `Bad_Request
        | Some project_id ->
            let%lwt tasks = Dream.sql request (Task_object.list project_id) in
            tasks
            |> yojson_of_list Task_object.yojson_of_t
            |> Yojson.Safe.to_string |> Dream.json);
    Dream.get "/projects/:project_id/tasks/:id" (fun request ->
        let project_id_param = Dream.param request "project_id" in
        let id_param = Dream.param request "id" in
        match
          (int_of_string_opt project_id_param, int_of_string_opt id_param)
        with
        | Some project_id, Some id ->
            let%lwt task = Dream.sql request (Task_object.find project_id id) in
            task |> Task_object.yojson_of_t |> Yojson.Safe.to_string
            |> Dream.json
        | _ -> Dream.empty `Bad_Request);
    Dream.post "/projects/:project_id/tasks/:id/lang/:lang" (fun request ->
        let project_id_param = Dream.param request "project_id" in
        let id_param = Dream.param request "id" in
        let lang_key = Dream.param request "lang" in
        match
          (int_of_string_opt project_id_param, int_of_string_opt id_param)
        with
        | Some project_id, Some id ->
            let%lwt value = Dream.body request in
            let%lwt () =
              Dream.sql request (Task_object.translate id lang_key value)
            in
            let%lwt task = Dream.sql request (Task_object.find project_id id) in
            task |> Task_object.yojson_of_t |> Yojson.Safe.to_string
            |> Dream.json
        | _ -> Dream.empty `Bad_Request);
  ]
