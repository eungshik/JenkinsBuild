#!/bin/sh
#
# Written by EungShik Kim on 2022.04.04
# Normalized by Henry Kim on 2023.11.29
# Madatory:
#     git      should be installed...
#
SCRIPT_PATH=$(dirname $0)
SCRIPT_NAME=$(basename $0)
function getPrefixOnly() {
  testString="${GIT_TAG_FULL}"
  if test ! -z "$1"; then
    testString="$1"
  fi
  onlyPrefixString="$(echo ${testString} | tr -d '[0-9]._' | tr '[:lower:]' '[:upper:]')"
  if test ! -z "${onlyPrefixString}"; then
    BUILD_TYPE="${onlyPrefixString}"
  fi
}
function getVersionOnly() {
  testString="${GIT_TAG_FULL}"
  if test ! -z "$1"; then
    testString="$1"
  fi
  onlyVersionString="$(echo ${testString} | tr -d [A-Za-z]-)"
  if test ! -z "${onlyVersionString}"; then
    VERSIONS="${onlyVersionString}"
  fi
}
function getLastTag() {
  LAST_FULL_TAG=$(git describe --tags --abbrev=0)
  getPrefixOnly ${LAST_FULL_TAG}
  getVersionOnly ${LAST_FULL_TAG}
  LAST_BUILD_TYPE="${BUILD_TYPE}"
  LAST_TAG="${VERSIONS}"
}
function getConfigPrefix() {
  if [ $USING_CONFIG -eq 1 ]; then
    tempOS="${INPUT_OS}"
    tempReleaseType="${RELEASE_TYPE}"
    if [[ "$INPUT_OS" == "both" ]]; then
      tempOS="android"
      tempReleaseType="develop"
    fi
    TAG_PREFIX="$(git config -f $CONFIG_FILE --get $tempOS".tagPrefix."$tempReleaseType)"
  fi
}
function getInputTag() {
  getVersionOnly
  if [ $USING_CONFIG -eq 1 ]; then
    getConfigPrefix
    upperGitFullTag="$(echo ${GIT_TAG_FULL} | tr '[:lower:]' '[:upper:]')"
    if [[ "${upperGitFullTag}" == "${TAG_PREFIX}"* ]]; then
      BUILD_TYPE="${TAG_PREFIX}"
    elif [[ "${VERSIONS}" == "${GIT_TAG_FULL}" ]]; then
      BUILD_TYPE="${TAG_PREFIX}"
    else
      printInputTag
      printUncorrectTagPrefixError
      exit
    fi
  else
    getPrefixOnly
  fi
  VERSION_STRING=( ${VERSIONS//./ })
  MARKET_VERSION="${VERSION_STRING[0]}.${VERSION_STRING[1]}.${VERSION_STRING[2]}"
  BUILD_NUMBER="${VERSION_STRING[3]}"
  FINAL_TAG="${BUILD_TYPE}${VERSIONS}"
}
function printLastTag() {
  getLastTag
  echo "  ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
  echo "           FYI - The last tag is '${LAST_BUILD_TYPE}${LAST_TAG}'"
  echo "  ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
}
ProceedOrNot=0
function printInputTag() {
  echo " ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
  echo "     Input tag is '${GIT_TAG_FULL}'"
  echo "     Input platform is '${INPUT_OS}'"
  echo "     Input release type is '${RELEASE_TYPE}'"
  if test ! -z "$CONFIG_FILE"; then
    if test -f "$CONFIG_FILE"; then
      echo "     Input config file is '${CONFIG_FILE}'"
      echo "     Parsed tag prefix is '${TAG_PREFIX}'" 
    fi
  fi
  if [ $ProceedOrNot -eq 1 ]; then
    echo "     Commit this version change, Push, and Proceed build on Jenkins, Are you sure? (Y/n)"
  fi
  if [ $DRY_RUN -eq 1 ]; then
    echo "     Is dry-run? ........................[YES]"
  fi
  echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
}
function printResult() {
  getLastTag
  echo " ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
  echo "     Result - Jenkins build as tag '$FINAL_TAG' started..."
  echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
}
function printUntrackError() {
  echo " ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
  echo "     There are some issues, maybe untracked files remained..."
  echo "     You can `git stash` untracked files for push!"
  echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
}
function printNotMainError() {
  echo " ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
  echo "     Branch is not `main`, you should checkout main branch"
  echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
}
function printUncommitError() {
  echo " ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
  echo "     WARNING!!! There are some issues, maybe uncommited files remained..."
  echo "     run git commit first..."
  echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
}
function printUncorrectTagPrefixError() {
  echo " ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
  echo "     error: syntax of input tag according to $CONFIG_FILE"
  echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
}
function matchPlatformOrNot() {
  # thanks to https://stackoverflow.com/a/50808490
  trap "$(shopt -p nocasematch)" RETURN
  # thanks to https://stackoverflow.com/a/1728814
  shopt -s nocasematch
  case "${INPUT_OS}" in
    "android" ) INPUT_OS="android";;
    "ios" ) INPUT_OS="ios";;
    "both" ) INPUT_OS="both";;
    * ) 
      $SCRIPT_PATH/$SCRIPT_NAME -h
      echo "error: unknown platform was specified => ${INPUT_OS}."
      echo ""
      exit
      ;;
  esac
}
function matchReleaseTypeOrNot() {
  # thanks to https://stackoverflow.com/a/50808490
  trap "$(shopt -p nocasematch)" RETURN
  # thanks to https://stackoverflow.com/a/1728814
  shopt -s nocasematch
  case "${RELEASE_TYPE}" in
    "release" ) RELEASE_TYPE="release";;
    "develop" ) RELEASE_TYPE="develop";;
    * ) 
      $SCRIPT_PATH/$SCRIPT_NAME -h
      echo "error: unknown release type was specified => ${RELEASE_TYPE}."
      echo ""
      exit
      ;;
  esac
}
function parsingPrefixAndDeclare() {
  tmpConfigFile=""
  if test -f "${CONFIG_FILE}"; then
    tmpConfigFile="${CONFIG_FILE}"
  elif test -f "dist.config"; then
    tmpConfigFile="dist.config"
  fi

  if test -f "${tmpConfigFile}"; then
    if [[ "${GIT_TAG_FULL}" == [A-Za-z]* ]]; then
      iosReleaseTagPrefix="$(git config -f ${tmpConfigFile} --get "ios.tagPrefix.release" | tr '[:lower:]' '[:upper:]')"
      aosReleaseTagPrefix="$(git config -f ${tmpConfigFile} --get "android.tagPrefix.release" | tr '[:lower:]' '[:upper:]')"
      developTagPrefix="$(git config -f ${tmpConfigFile} --get "android.tagPrefix.develop" | tr '[:lower:]' '[:upper:]')"
      getPrefixOnly
      if [[ "${BUILD_TYPE}" == "${iosReleaseTagPrefix}" ]]; then
        RELEASE_TYPE="release"
        INPUT_OS="ios"
        TAG_PREFIX="${BUILD_TYPE}"
        CONFIG_FILE="${tmpConfigFile}"
        USING_CONFIG=1
      elif [[ "${tmpBuildType}" == "${aosReleaseTagPrefix}" ]]; then
        RELEASE_TYPE="release"
        INPUT_OS="android"
        TAG_PREFIX="${BUILD_TYPE}"
        CONFIG_FILE="${tmpConfigFile}"
        USING_CONFIG=1
      elif [[ "${tmpBuildType}" == "${developTagPrefix}" ]]; then
        RELEASE_TYPE="develop"
        TAG_PREFIX="${BUILD_TYPE}"
        CONFIG_FILE="${tmpConfigFile}"
        USING_CONFIG=1
      fi
    fi
  fi
}
function spinner() {
    local i sp n
    sp='/-\|'
    n=${#sp}
    printf '  Wait a moment... '
    while sleep 0.1; do
        printf "%s\b" "${sp:i++%n:1}"
    done
}
## Default variables
UPDATE_VERSION=0
DRY_RUN=0
USING_CONFIG=0
TAG_PREFIX=""
## Parsing arguments, https://stackoverflow.com/a/14203146
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -p | --platform)
    INPUT_OS="$2"
    shift # past argument
    shift # past value
    ;;
  -t | --tag)
    GIT_TAG_FULL="$2"
    shift # past argument
    shift # past value
    ;;
  -c | --config)
    CONFIG_FILE="$2"
    shift # past argument
    shift # past value
    ;;
  -r | --release-type)
    RELEASE_TYPE="$2"
    shift # past argument
    shift # past value
    ;;
  -a | --auto-update)
    UPDATE_VERSION=1
    shift # past argument
    ;;
  --dry-run)
    DRY_RUN=1
    shift # past argument
    ;;
  * | -h | --help) # unknown option
    shift          # past argument
    echo "usage: $SCRIPT_NAME [ -t | --tag <tag name>] [ -p | --platform {ios|android|both}] "
    echo "          [ -c | --config <config_file>] [ -r | --release-type {release|develop}] "
    echo "          [ -a | --auto-update] [ --dry-run]"
    echo ""
    echo "examples:"
    echo "       $SCRIPT_NAME -p both -t '1.0.0' -r develop"
    echo "       $SCRIPT_NAME -p ios -t '1.0.0' -a -r release"
    echo "       $SCRIPT_NAME -p android -t '1.0.0' -c dist.config"
    echo "       $SCRIPT_NAME -p android -t '1.0.0' -c dist.config --dry-run"
    echo ""
    echo "mandatory arguments:"
    echo "   -t, --tag          git tag to be added with <tag name: Major.Minor.Point.Build> such like followings:"
    echo "                        eg. tag prefix 'D-1.0.0' means test build for both iOS and Android platform"
    echo "                        eg. tag prefix 'RA-4.1.3.777' means release build for Android platform"
    echo "                        eg. tag prefix 'RI-7.2.9.450' means release build for iOS platform"
    echo ""
    echo "optional arguments:"
    echo "   -h, --help         show this help message and exit:"
    echo "   -p, --platform     {ios|android|both}, default is both"
    echo "                      assign platform as iOS or Android or both to processing"
    echo "   -c, --config       <config_file>"
    echo "                      can copy file from $SCRIPT_PATH/dist.config.default"
    echo "   -r, --release-type {release|develop}, default is develop"
    echo "   -a, --auto-update  update project version string(code) in project. and commit & push automatically"
    echo "   --dry-run          dry run only instead of real processing with git command"
    echo ""
    echo "example of config file: (git config style)"
    # thanks to ascii from https://en.wikipedia.org/wiki/Box-drawing_character
    echo "┌─────── dist.config ───────────┐"
    cat $SCRIPT_PATH/dist.config.default | sed -e 's/^\(.*\)$/   \1/g'
    echo "└───────────────────────────────┘"
    echo ""
    printLastTag
    exit
    ;;
  esac
done
if test -z "$GIT_TAG_FULL"; then
    $SCRIPT_PATH/$SCRIPT_NAME -h
    echo ""
    echo "error: no tag name specified."
    echo ""
    exit
fi
if test ! -z "$INPUT_OS"; then
  matchPlatformOrNot
else
    INPUT_OS="both"
    # $SCRIPT_PATH/$SCRIPT_NAME -h
    # echo ""
    # echo "error: no platform type specified."
    # echo ""
    # exit
fi
if test ! -z "$CONFIG_FILE"; then
    if test ! -f "$CONFIG_FILE"; then
      $SCRIPT_PATH/$SCRIPT_NAME -h
      echo ""
      echo "error: no config file in $CONFIG_FILE"
      echo ""
      exit
    fi

    USING_CONFIG=1
fi
if test ! -z "$RELEASE_TYPE"; then
    matchReleaseTypeOrNot
else
    # Set default release type as develop
    RELEASE_TYPE="develop"

    # if exist dist.config
    parsingPrefixAndDeclare
fi
###
###
if [ -z "$(git status --untracked-files=no --porcelain --ignore-submodules)" ]; then
  # Working directory clean excluding untracked files

  getInputTag
  printInputTag

  if [ ! -z "$(git tag | grep '${FINAL_TAG}')" ]; then
    echo " ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
    echo "     Input tag '$BUILD_TYPE$MARKET_VERSION.$BUILD_NUMBER' is exist, delete it? (Y/n)"
    echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
    read -n1 Answer
    if [ "$Answer" == "Y" -o "$Answer" == "y" ]; then
      git tag -d '${FINAL_TAG}'
    else
      exit
    fi
  fi

  if [ $UPDATE_VERSION -eq 1 ]; then
    if [[ "$INPUT_OS" == "ios" || "$INPUT_OS" == "both" ]]; then
      spinner &
      spinner_pid=$!
      IOS_FILE="$(find . -name 'project.pbxproj' | grep -v 'Pods' | grep -v 'node_modules')"
      # TODO: get rid of stderr from kill
      kill $spinner_pid > /dev/null 2>&1 # kill the spinner

      if [ -f "$IOS_FILE" ]; then
        oldMarketingVersion="$(grep 'MARKETING_VERSION =' $IOS_FILE | sort | uniq | xargs)"
        oldCurrentProjectVersion="$(grep 'CURRENT_PROJECT_VERSION =' $IOS_FILE | sort | uniq | xargs)"
        cat $IOS_FILE | \
        sed -e "s/CURRENT_PROJECT_VERSION = \(.*\);/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" | \
        sed -e "s/MARKETING_VERSION = \(.*\);/MARKETING_VERSION = $MARKET_VERSION;/g" \
        > $IOS_FILE.new
        
        echo ""
        if [ $DRY_RUN -eq 1 ]; then
          echo " ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
          echo "    (DEBUG)"
          echo "    iOS: mv $IOS_FILE.new $IOS_FILE"
          echo "    ${oldMarketingVersion}  <== ${MARKET_VERSION}"
          echo "    ${oldCurrentProjectVersion}  <== ${BUILD_NUMBER}"
          echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
          rm $IOS_FILE.new
        else
          mv $IOS_FILE.new $IOS_FILE
          echo " ┍━━ iOS project.pbxproj ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
          echo "    update ${oldMarketingVersion} into ${MARKET_VERSION} ....... [DONE]"
          echo "    update ${oldCurrentProjectVersion} into ${BUILD_NUMBER} ........ [DONE]"
          echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
        fi
      fi
    fi

    if [[ "$INPUT_OS" == "android" || "$INPUT_OS" == "both" ]]; then
      spinner &
      spinner_pid=$!

      # thanks to https://stackoverflow.com/a/70940482
      AOS_FILE="$(find . -name 'build.gradle' -exec grep -lirZ '^apply plugin' {} \; | xargs grep -li 'com.android.application' | xargs grep -li 'applicationId' | grep -v 'node_modules')"
      # TODO: get rid of stderr from kill
      kill $spinner_pid > /dev/null 2>&1 # kill the spinner

      if [ -f "$AOS_FILE" ]; then
        oldVersionName="$(grep 'versionName' $AOS_FILE | sort | uniq | xargs)"
        oldVersionCode="$(grep 'versionCode ' $AOS_FILE | sort | uniq | xargs)"
        cat $AOS_FILE | \
        sed -e "/versionCode =/!s/versionCode .*/versionCode $BUILD_NUMBER/g" | \
        sed -e "s/versionName \".*\"/versionName \"$MARKET_VERSION\"/g" \
        > $AOS_FILE.new

        echo ""
        if [ $DRY_RUN -eq 1 ]; then
          echo " ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
          echo "    (DEBUG)"
          echo "    Android: mv $AOS_FILE.new $AOS_FILE"
          echo "    ${oldVersionName}  <== ${MARKET_VERSION}"
          echo "    ${oldVersionCode}  <== ${BUILD_NUMBER}"
          rm $AOS_FILE.new
          echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
        else
          mv $AOS_FILE.new $AOS_FILE
          echo " ┍━━ Android app > build.gradle ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
          echo "    update ${oldVersionName} into ${MARKET_VERSION} ...... [DONE]"
          echo "    update ${oldVersionCode} into ${BUILD_NUMBER} .......... [DONE]"
          echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
        fi
      fi
    fi
  fi

  Type="${RELEASE_TYPE}"
  OS="${INPUT_OS}"
  REMOTE_REPO="$(git remote -v  | grep 'github.com' | grep '(push)' | awk '{print $1}' | tr -d ' ')"
  if [ $UPDATE_VERSION -eq 1 ]; then
    echo "Commit this version changing, Push tag(${FINAL_TAG}), and Proceed build on Jenkins"
  else
    echo "Push tag(${FINAL_TAG}), and Proceed build on Jenkins"
  fi
  # thanks to https://stackoverflow.com/a/226724
  while true; do
      read -n1 -p "Are you sure? (y/n) " yn
      case $yn in
          [Yy]* )
              echo ""
              CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
              if [ $UPDATE_VERSION -eq 1 -a $DRY_RUN -eq 0 ]; then
                git commit -a -m "Update version $Type v${MARKET_VERSION} build($BUILD_NUMBER) for $OS"
                git push $REMOTE_REPO $CURRENT_BRANCH
                echo " ┍━━━ commit & push version changed ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
                echo "    git commit -a -m \"Update version $Type v${MARKET_VERSION} build($BUILD_NUMBER) for $OS\" ..... [DONE]"
                echo "    git push $REMOTE_REPO $CURRENT_BRANCH ..... [DONE]"
                echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
              else
                echo "(DEBUG) processing command: git commit -a -m \"Update version $Type v${MARKET_VERSION} build($BUILD_NUMBER) for $OS\""
                echo "(DEBUG) processing command: git push ${REMOTE_REPO} ${CURRENT_BRANCH}"
              fi
            break;;
          [Nn]* ) 
              echo ""
              echo "bye"
              exit;;
          * ) 
              echo ""
              echo "Please answer yes or no.";;
      esac
  done
  FINAL_TAG=$(echo ${FINAL_TAG} | tr -d "'" | tr -d '"')
  if [ $DRY_RUN -eq 1 ]; then
    echo "(DEBUG) processing command: git tag -a ${FINAL_TAG}"
    echo "(DEBUG) processing command: git push --tags ${REMOTE_REPO}"
  else
    git tag -a ${FINAL_TAG} -m "${Type} build for ${OS}"
    git push --tags ${REMOTE_REPO}
    echo " ┍━━━ add tag & push to remote ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑"
    echo "    git tag -a ${FINAL_TAG} -m \"${Type} build for ${OS}\" ..... [DONE]"
    echo "    git push --tags ${REMOTE_REPO} ..... [DONE]"
    echo " ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙"
  fi
else 
  # Uncommitted changes error
  printUncommitError
  exit
fi

printResult
