{{- /*

  Loads all script files into the "/scripts" mount point.

*/ -}}

{{- define "load_scripts" -}}
{{- $global := index . 0 -}}
set -e
{{- range $i, $prefix := index . 1 -}}
  {{- range $path, $content := $global.Files.Glob "scripts/*.sh" }}
    {{- $name := trimPrefix "scripts/" $path }}
echo "/scripts/{{ $name }}"
    {{- if or ( hasPrefix $prefix $name ) ( hasPrefix "common" $name ) }}
printf '%s' "{{ $content | toString | b64enc }}" |base64 -d >"/scripts/{{ $name }}"
    {{- end }}
  {{- end }}
ls /scripts/{{ $prefix }}*.sh;
chmod +x /scripts/{{ $prefix }}*.sh;
{{- end }}

{{- range $i, $script := index . 2 -}}
echo "Running Script {{ $script }}";
  {{ $script }};
{{- end }}
{{- end -}}
