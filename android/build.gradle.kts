allprojects {
    repositories {
        google()
        maven { url = uri("https://dl.cloudsmith.io/public/arthenica/ffmpeg-kit/maven/release/") }
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    
    repositories {
        google()
        maven { url = uri("https://dl.cloudsmith.io/public/arthenica/ffmpeg-kit/maven/release/") }
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            force("com.arthenica:ffmpeg-kit-full:6.0-2.LTS")
            eachDependency {
                if (requested.group == "com.arthenica" && requested.name.startsWith("ffmpeg-kit")) {
                    useVersion("6.0-2.LTS")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
