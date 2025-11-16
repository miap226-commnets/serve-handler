#!/usr/bin/env bash
set -euo pipefail

SBOM="${1:-sbom.spdx.json}"
if [ ! -f "$SBOM" ]; then
  echo "SBOM file not found: $SBOM" >&2
  exit 1
fi

# 依赖总数（所有独立组件）
TOTAL_PACKAGES="$(jq '.packages | length' "$SBOM")"

# 唯一许可证集合（优先 concluded，其次 declared），剔除空和 NOASSERTION
mapfile -t UNIQUE_LICENSES < <(jq -r '
  [ .packages[] | .licenseConcluded, .licenseDeclared ]
  | map(select(. != null and . != "NOASSERTION"))
  | unique | sort | .[]
' "$SBOM")

# 生成 metrics.txt（用于填表）
{
  echo "Total dependencies (all scopes): ${TOTAL_PACKAGES}"
  echo "Unique license types:"
  for lic in "${UNIQUE_LICENSES[@]:-}"; do
    echo "- ${lic}"
  done
} > metrics.txt

# 导出 CSV：名称,版本,licenseDeclared,licenseConcluded,purl
jq -r '
  ["name","version","licenseDeclared","licenseConcluded","purl"],
  (
    .packages[]
    | . as $p
    | [
        ($p.name // ""),
        ($p.versionInfo // ""),
        ($p.licenseDeclared // ""),
        ($p.licenseConcluded // ""),
        (
          ($p.externalRefs // [])
          | map(select(.referenceType=="purl"))[0]?.referenceLocator // ""
        )
      ]
    | @csv
  )
' "$SBOM" > spdx-dependencies.csv

echo "Wrote metrics.txt and spdx-dependencies.csv"
