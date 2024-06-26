# Copyright (c) 2017 - present Adobe Systems Incorporated. All rights reserved.

# Licensed under the MIT License (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# https://opensource.org/licenses/MIT

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

__search_path_not_found() {
    err_part1=$(decorate_error <<-HEREDOC
    Search path ${1} does not exist
    You must create it
HEREDOC
)

generate_snippet=$(cat <<-HEREDOC
mkdir -p ${1}
HEREDOC
)
err_part2=$(decorate_error <<'HEREDOC'
    Then, try auto-complete again
HEREDOC
)

    # echo -ne "${err}\n$generate_snippet"
    echo -ne "\n${err_part1}\n${generate_snippet}\n${err_part2}"
}

__search_path_is_empty() {
    err_part1=$(decorate_error <<-HEREDOC
    Search pattern ${1}/${2} is empty
    You must create entries first
HEREDOC
)

    # echo -ne "${err}\n$generate_snippet"
    echo -ne "\n${err_part1}"
}

__suggest_from_path() {
    __safe_set_bash_setting 'u'
    local search_path=${1}
    local search_filter=${2:-}
    __safe_unset_bash_setting 'u'

    # test search path exists
    _cmd="test -d \"${search_path}\""
    run_cmd_silent "${_cmd}" "" "$(__search_path_not_found ${search_path})"
    result=$?

    # if the folder does not exist, stop building suggestions
    if [ "${result}" -ne 0 ]; then
        # leave this line here to avoid printing error messages multiple times
        echo "================================================="
        return 1
    fi

    # find and store suggestions
    contents="$(ls -A ${search_path} | grep "${search_filter}")"

    # test search path not empty folder
    _cmd="test -n \"${contents}\""
    run_cmd_silent "${_cmd}" "" "$(__search_path_is_empty ${search_path} ${search_filter})"
    result=$?

    # if the folder is empty, there are no suggestions to give
    if [ "${result}" -ne 0 ]; then
        # leave this line here to avoid printing error messages multiple times
        echo "================================================="
        return 1
    fi

    # otherwise, print suggestions
    echo "${contents}"
}

_tfm_suggest_product() {
    __suggest_from_path "${TF_PROJECT_CONFIG_PATH}"
    return $?
}

_tfm_suggest_repo() {
    # the only suggestion we can think of is the repository name
    echo "${__tfm_project_dir##*/}"
    return $?
}

_tfm_suggest_module() {
    __suggest_from_path "${TF_MODULE_PATH}"
    return $?
}

_tfm_suggest_env() {
    # input vars
    __safe_set_bash_setting 'u'
    local selected_product="${1}"
    local selected_module="${2}"
    __safe_unset_bash_setting 'u'

    # find env folders for the selected product and module
    find "${__tfm_env_rel_path}/${selected_product}" -type d -mindepth 2 -name "${selected_module}" | sed "s,${__tfm_env_rel_path}/${selected_product}/,,g" | sed "s,/${selected_module},,g"
    return $?
}

_tfm_suggest_config() {
    # input vars
    __safe_set_bash_setting 'u'
    local selected_product="${1}"
    local selected_env="${2}"
    local selected_module="${3}"
    local search_filter="${4:-.*\.tfvars}"
    __safe_unset_bash_setting 'u'

    # find config files
    __suggest_from_path "${TF_PROJECT_CONFIG_PATH}/${selected_product}/${selected_env}/${selected_module}" "${search_filter}" | grep -v 'tfplan' | sed 's,\.tfvars,,g'
    return $?
}

_tfm_suggest_action()
{
    echo "${__tfm_allowed_actions[@]}"
    return $?
}

_tfm_suggest_workspace_override()
{
    echo "workspace=default"
    return $?
}

_tf_manage_complete() {
    # helper bootstrap
    TOOL_TLDIR=$(cd $(dirname $(readlink $(which tf))) && git rev-parse --show-toplevel && cd - > /dev/null)

    # import bash framework
    source "${TOOL_TLDIR}/vendor/bash-framework/lib/import.sh"

    # import TF wrapper modules
    source "${TOOL_TLDIR}/lib/import.sh"

    # try loading the global config
    __load_global_config
    result=$?

    # if we have a config error, do not continue to build suggestions
    if [ "${result}" -ne 0 ]; then
        # leave this line here to avoid printing error messages multiple times
        echo "================================================="
        return 1
    fi

    # try loading the project config
    __load_project_config
    result=$?

    # if we have a config error, do not continue to build suggestions
    if [ "${result}" -ne 0 ]; then
        # leave this line here to avoid printing error messages multiple times
        echo "================================================="
        return 1
    fi

    # get global variables inferred by the wrapper
    __compute_common_paths

    # initialize bash completion variables
    local cur_word prev_word type_list

    # COMP_WORDS is an array of words in the current command line.
    # COMP_CWORD is the index of the current word (the one the cursor is
    # in). So COMP_WORDS[COMP_CWORD] is the current word; we also record
    # the previous word here, although this specific script doesn't
    # use it yet.
    cur_word="${COMP_WORDS[$COMP_CWORD]}"
    prev_word="${COMP_WORDS[$COMP_CWORD-1]}"

    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$(_tfm_suggest_product)" -- $cur_word) )
    elif [ $COMP_CWORD -eq 2 ]; then
        COMPREPLY=( $(compgen -W "$(_tfm_suggest_module)" -- $cur_word) )
    elif [ $COMP_CWORD -eq 3 ]; then
        selected_module="${COMP_WORDS[$COMP_CWORD-1]}"
        selected_product="${COMP_WORDS[$COMP_CWORD-2]}"
        COMPREPLY=( $(compgen -W "$(_tfm_suggest_env "${selected_product}" "${selected_module}")" -- $cur_word) )
    elif [ $COMP_CWORD -eq 4 ]; then
        selected_env="${COMP_WORDS[$COMP_CWORD-1]}"
        selected_module="${COMP_WORDS[$COMP_CWORD-2]}"
        selected_product="${COMP_WORDS[$COMP_CWORD-3]}"
        COMPREPLY=( $(compgen -W "$(_tfm_suggest_config "${selected_product}" "${selected_env}" "${selected_module}")" -- $cur_word) )
    elif [ $COMP_CWORD -eq 5 ]; then
        COMPREPLY=( $(compgen -W "$(_tfm_suggest_action)" -- $cur_word) )
    elif [ $COMP_CWORD -eq 6 ]; then
        COMPREPLY=( $(compgen -W "$(_tfm_suggest_workspace_override)" -- $cur_word) )
    else
        COMPREPLY=()
    fi
    return 0
}

# Register _tf_manage_complete to provide completion for the following commands
complete -F _tf_manage_complete tf
