### À faire avant de merger : aligner l'opérateur Spark sur le cluster

Cette PR fait passer Spark en `{{SPARK_VERSION}}`, mais le `SparkApplication` est exécuté par `kubeflow/spark-operator`, dont la version vit dans **fleet-infra** et n'est pas visible depuis ce dépôt.

Vérifier que la version de l'opérateur déployée supporte Spark `{{SPARK_VERSION}}` : <https://github.com/kubeflow/spark-operator#version-matrix>

Si la matrice demande une version d'opérateur plus récente, la bumper dans `fleet-infra` **avant** de merger ici : un `spec.sparkVersion` que l'opérateur en place ne connaît pas fait échouer la soumission du driver, et le DAG casse en production, pas en CI.
