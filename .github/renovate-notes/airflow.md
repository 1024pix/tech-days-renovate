### À faire avant de merger : régénérer les contraintes uv

`[tool.uv] constraint-dependencies` n'est **pas** mis à jour par cette PR. Le manager `pep621` de Renovate ne lit pas cette clé (il couvre `project.dependencies`, `project.optional-dependencies`, `dependency-groups`, `build-system.requires` et les sections dev de `tool.pdm` / `tool.uv`), donc ces pins restent ceux de l'ancienne version d'Airflow.

Sur cette branche :

```bash
./helpers/update_airflow_constraints.sh {{AIRFLOW_VERSION}} {{PYTHON_VERSION}}
uv lock
```

Puis commiter `pyproject.toml` et `uv.lock`.

Si le script s'arrête sur une erreur de téléchargement, le fichier de contraintes amont n'existe pas pour ce couple de versions : vérifier la branche `constraints-{{AIRFLOW_VERSION}}` et le fichier `constraints-no-providers-{{PYTHON_VERSION}}.txt` sur le dépôt `apache/airflow`.
