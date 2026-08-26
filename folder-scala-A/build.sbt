import org.typelevel.scalacoptions.ScalacOptions

ThisBuild / scalaVersion := "2.12.0"
ThisBuild / version := "0.1.0-SNAPSHOT"
ThisBuild / organization := "com.example"
ThisBuild / organizationName := "example"

// cf https://github.com/typelevel/sbt-tpolecat?tab=readme-ov-file#scalatest-warnings
Test / tpolecatExcludeOptions += ScalacOptions.warnNonUnitStatement

// cf https://stackoverflow.com/questions/73465937/apache-spark-3-3-0-breaks-on-java-17-with-cannot-access-class-sun-nio-ch-direct
Test / javaOptions ++= Seq(
  "--add-exports=java.base/sun.nio.ch=ALL-UNNAMED",
  "--add-exports=java.base/sun.util.calendar=ALL-UNNAMED",
)

lazy val root = (project in file("."))
  .settings(
    name := "data-processing",
    libraryDependencies += "org.postgresql" % "postgresql" % "42.7.13",
    // spark-core and spark-sql ship inside the Spark base image (see Dockerfile
    // Stage 2), so they are Provided: on the compile/test classpath but excluded
    // from the runtime classpath that gets pre-cached into the image.
    libraryDependencies += "org.apache.spark" %% "spark-core" % "3.5.5" % Provided,
    libraryDependencies += "org.apache.spark" %% "spark-sql" % "3.5.5" % Provided,
    // spark-hadoop-cloud (and its hadoop-aws / aws-sdk transitives) is NOT in the
    // base image, so it stays a runtime dependency and is pre-cached in Docker
    // (see Dockerfile Stage 1 sbt-dependencies).
    libraryDependencies += "org.apache.spark" %% "spark-hadoop-cloud" % "3.5.5",
    libraryDependencies += "org.scalactic" %% "scalactic" % "3.2.19",
    libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.19" % "test",
    libraryDependencies += "com.holdenkarau" %% "spark-testing-base" % "3.5.5_2.0.1" % "test",
    Test / fork := true,
    Test / parallelExecution := false,
    artifactName := { (sv: ScalaVersion, module: ModuleID, artifact: Artifact) =>
      "data-processing.jar"
    },
    wartremoverErrors ++= Warts.unsafe,
    wartremoverErrors += Wart.Enumeration,
  )

// Stage the runtime dependency JARs (everything on the Runtime classpath that is
// NOT Provided by the Spark base image) into target/docker-jars. The Dockerfile
// Stage 1 runs `sbt stageRuntimeJars` and copies these into /opt/spark/jars so
// Spark pods never resolve dependencies at startup. Driven entirely by the
// libraryDependencies above, so build.sbt stays the single source of truth.
//
// The Scala standard library is excluded: sbt auto-adds scala-library/scala-reflect
// for the project's scalaVersion, but the Spark base image already ships its own
// matching pair. Staging ours would drop e.g. scala-library.jar next to the base
// image's scala-library-<v>.jar, leaving two copies on the classpath with a
// nondeterministic load order (2.12.x is binary compatible, so the base copy is safe).
lazy val stageRuntimeJars = taskKey[File](
  "Copy runtime dependency JARs into target/docker-jars for Docker pre-cache",
)
stageRuntimeJars := {
  val dest = target.value / "docker-jars"
  IO.delete(dest)
  IO.createDirectory(dest)
  val baseImageProvided = Set("scala-library", "scala-reflect")
  val jars = (Runtime / managedClasspath).value
    .map(_.data)
    .filter(_.getName.endsWith(".jar"))
    .filterNot(jar => baseImageProvided.contains(jar.getName.stripSuffix(".jar")))
  jars.foreach(jar => IO.copyFile(jar, dest / jar.getName))
  streams.value.log.info(s"Staged ${jars.size} runtime JARs into $dest")
  dest
}
