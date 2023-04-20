{{- /*

  This template is meant to translate the Tekton placeholder utilized by the shell scripts, thus the
  scripts can rely on a pre-defined and repetable way of consuming Tekton attributes.

    Example:
      The placeholder `workspaces.a.b` becomes `WORKSPACES_A_B`

*/ -}}
{{- define "environment" -}}
    {{- range list
          "params.APP_IMAGE"
          "params.BUILDER_IMAGE"
          "params.CNB_PLATFORM_API"
          "params.SUBDIRECTORY"
          "params.PROCESS_TYPE"
          "params.BINDINGS_GLOB"
          "params.RUN_IMAGE"
          "params.CACHE_IMAGE"
          "params.SKIP_RESTORE"
          "params.USER_ID"
          "params.GROUP_ID"
          "params.VERBOSE"
          "workspaces.source.path"
          "workspaces.cache.bound"
          "workspaces.cache.path"
          "workspaces.bindings.bound"
          "workspaces.bindings.path"
          "results.APP_IMAGE_DIGEST.path"
          "results.APP_IMAGE_URL.path"
    }}
- name: {{ . | upper | replace "." "_" | replace "-" "_" }}
  value: "$({{ . }})"
    {{- end -}}
{{- end -}}
