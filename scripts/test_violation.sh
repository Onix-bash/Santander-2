pmd_config_path="config/scanner/pmd_config.xml"

sf scanner:run --target "src" --severity-threshold=2 --verbose-violations --format csv --pmdconfig $pmd_config_pat