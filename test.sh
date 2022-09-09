# Declare and print ENV VARS
          SPARK_VERSION="3.2.1"
          echo "Spark Version: $SPARK_VERSION"
          HADOOP_VERSION="3.2"
          echo "Hadoop Version: $HADOOP_VERSION"
          SCALA_VERSION=""
          echo "Scala Version: $SCALA_VERSION"
          PY4J_VERSION="0.10.9"
          echo "Py4j Version: $PY4J_VERSION"
          INSTALL_SLUG="spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION$SCALA_VERSION"
          SPARK_URL="https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/$INSTALL_SLUG.tgz"
          echo "Spark download URL: $SPARK_URL"
          echo "Workspace: $GITHUB_WORKSPACE"
          
          # Split string and insert into array
          IFS='/'
          read -a PATH_PARTS <<< "$GITHUB_WORKSPACE"

          # Iterate thru array and recreate path
          # Ignore last path part and empty strings
          INSTALL_ROOT_FOLDER=''
          for ((idx=0; idx<${#PATH_PARTS[@]}-1; ++idx)); do
              # Debug
              echo "$idx" "${PATH_PARTS[idx]}"

              # Concat string
              if ! [   "${PATH_PARTS[idx]}" = ""  ];
              then 
                INSTALL_ROOT_FOLDER+="/${PATH_PARTS[idx]}"
                # Debug
                echo "$INSTALL_ROOT_FOLDER"
              fi
          done
          echo "Proposed install folder: $INSTALL_ROOT_FOLDER"

          # Check if proposed folder is writable
          # If not, revert install folder to GITHUB_WORKSPACE
          if [ -w "$INSTALL_ROOT_FOLDER" ];
          then
            echo "Proposed install root folder is writeable"
          else
            echo "Proposed install folder is not writeable, reverting to workspace folder"
            INSTALL_ROOT_FOLDER="$GITHUB_WORKSPACE"
          fi
          
          # Debug
          echo "Final install root folder: $INSTALL_ROOT_FOLDER"

          INSTALL_PATH="$INSTALL_ROOT_FOLDER/$INSTALL_SLUG"
          echo Checking if full install path exits
          if [ -d "$INSTALL_PATH" ];
          then
            echo "Following install path located in runner: $INSTALL_PATH"
            echo "Deleting..."
            rm -rf "$INSTALL_PATH"
          else
            echo "No path found continuing with install"
          fi
          
          echo "Downloading..."
          cd /tmp &&
          wget -q -O spark.tgz "$SPARK_URL" &&
          tar xzf spark.tgz -C "$INSTALL_ROOT_FOLDER" &&
          rm spark.tgz &&
          ln -sf "$INSTALL_PATH" "$INSTALL_ROOT_FOLDER/spark" &&
          echo "Installation completed at: $INSTALL_PATH" ||
          echo "Installation failed."

          echo "Setting up environment variables"
          export SPARK_HOME="$INSTALL_ROOT_FOLDER/spark"
          export SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx2048M --driver-java-options=-Dlog4j.logLevel=info"
          export PYTHONPATH="$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-$PY4J_VERSION-src.zip"
          export PYSPARK_PYTHON="python"
          export PYSPARK_DRIVER_PYTHON="python"
          export HADOOP_VERSION="$HADOOP_VERSION"
          export APACHE_SPARK_VERSION="$SPARK_VERSION"
          export PATH="$SPARK_HOME/bin:$PATH"