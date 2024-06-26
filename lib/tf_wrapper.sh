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

_yin_yang_utf="\xe2\x98\xaf"
_GENERIC_ERR_MESSAGE_text="\nNice job, you broke it!\n${_yin_yang_utf}   Take a DEEP breath   ${_yin_yang_utf}\nLet's stop for a moment and think about where you're screwing up..."
_GENERIC_ERR_MESSAGE=$(echo -e "${_GENERIC_ERR_MESSAGE_text}" | decorate_error)

__run_action_plan() {
    debug "Entered ${FUNCNAME}"

    # vars
    local var_file_path="${TF_VAR_FILE_PATH}"
    local plan_file_path="${TF_PLAN_FILE_PATH}"
    local detailed_exitcode_flag='disabled'

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} -var-file='${var_file_path}' -out '${plan_file_path}' ${_TFM_EXTRA_VARS} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_magenta "terraform plan")"
    local _extra_notice="This $(__add_emphasis_green 'will not') affect infrastructure resources."
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'
    _flags[4]="no_print_message"

    if [[ "${_TF_ACTION_FLAGS}" =~ '-detailed-exitcode' ]]; then
        detailed_exitcode_flag='enabled'
        _flags[9]='0 2'
    fi

    # notify user
    info "${_message}"
    info "${_extra_notice}"

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
    result=$?

    if [ "${detailed_exitcode_flag}" = 'enabled' ]; then
        if [ "${result}" -eq 2 ]; then
            info "Terraform plan detected changes"
        elif [ "${result}" -eq 1 ]; then
            info "Terraform plan detected errors"
            exit 1
        fi
    fi

    # inform user .tfplan file was created
    local plan_file_emph="$(__add_emphasis_blue "${plan_file_path}")"
    info "Created Terraform plan file: ${plan_file_emph}"

    return ${result}
}

__run_action_apply_plan() {
    # vars
    local plan_file_path="${TF_PLAN_FILE_PATH}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} apply '${plan_file_path}' ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_red "terraform apply")"
    local _extra_notice="This $(__add_emphasis_red 'will') affect infrastructure resources."
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'
    _flags[4]="no_print_message"

    # notify user
    info "${_message}"
    info "${_extra_notice}"

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_apply() {
    # vars
    local var_file_path="${TF_VAR_FILE_PATH}"
    local extra_tf_args=""

    # append extra arguments in case we're running in "unattended" mode
    [ "${TF_EXEC_MODE}" = 'unattended' ] && local extra_tf_args=" -input=false -auto-approve"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} apply -var-file='${var_file_path}'${extra_tf_args} ${_TFM_EXTRA_VARS} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_red "terraform apply")"
    local _extra_notice="This $(__add_emphasis_red 'will') affect infrastructure resources."
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'
    _flags[4]="no_print_message"

    # notify user
    info "${_message}"
    info "${_extra_notice}"

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_destroy() {
    debug "Entered ${FUNCNAME}"

    # vars
    local var_file_path="${TF_VAR_FILE_PATH}"

    # append extra arguments in case we're running in "unattended" mode
    [ "${TF_EXEC_MODE}" = 'unattended' ] && local extra_tf_args=" -auto-approve"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} -var-file='${var_file_path}'${extra_tf_args} ${_TFM_EXTRA_VARS} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_red "terraform destroy")"
    local _extra_notice="This $(__add_emphasis_red 'will DESTROY') infrastructure resources."
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'
    _flags[4]="no_print_message"

    # notify user
    info "${_message}"
    info "${_extra_notice}"

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_get() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform get")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_output() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform output")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_show() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform show")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_state() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform state")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_workspace() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform workspace")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_taint() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform taint")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_untaint() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform untaint")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_import() {
    # vars
    local var_file_path="${TF_VAR_FILE_PATH}"
    local extra_tf_args=""

    # append extra arguments in case we're running in "unattended" mode
    [ "${TF_EXEC_MODE}" = 'unattended' ] && local extra_tf_args=" -input=false -auto-approve"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} import -var-file='${var_file_path}'${extra_tf_args} ${_TFM_EXTRA_VARS} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_red "terraform import")"
    local _extra_notice="This $(__add_emphasis_red 'will') affect infrastructure resources."
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'
    _flags[4]="no_print_message"

    # notify user
    info "${_message}"
    info "${_extra_notice}"

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_providers() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform ${_TF_ACTION}")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_init() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform init")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_refresh() {
    debug "Entered ${FUNCNAME}"

    # vars
    local var_file_path="${TF_VAR_FILE_PATH}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} ${_TF_ACTION} -var-file='${var_file_path}' ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform refresh")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_fmt() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} fmt ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform fmt")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__run_action_validate() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} validate ${_TF_ACTION_FLAGS}"
    local _message="Executing $(__add_emphasis_green "terraform validate")"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[0]='strict'
    _flags[1]='print_cmd'

    # execute
    run_cmd "${_cmd}" "${_message}" "${_flags[@]}" "${_GENERIC_ERR_MESSAGE}"
}

__get_tf_version() {
    debug "Entered ${FUNCNAME}"

    # build wrapper command
    local _cmd="${_TFM_TF_CMD} --version | head -1 | grep -o 'v.*'"
    local _message="Getting terraform version"
    local _flags=(${_DEFAULT_CMD_FLAGS[@]})
    _flags[4]="no_print_message"
    _flags[5]="no_print_status"
    _flags[6]="no_print_outcome"

    # store
    export _TF_VERSION=$(run_cmd "${_cmd}" "${_message}" "${_flags[@]}")
}

## Main Terraform wrapper control logic
__tf_controller() {
    _TFM_EXTRA_VARS="-var 'tfm_product=${_PRODUCT}' -var 'tfm_repo=${_REPO}' -var 'tfm_module=${_MODULE}' -var 'tfm_env=${_ENV}' -var 'tfm_module_instance=${_MODULE_INSTANCE}'"
    _TFM_TF_CMD="terraform"

    # get Terraform version from CLI
    __get_tf_version

    # notify user
    notice_msg="*** Terraform ${_TF_VERSION} ***"
    info "$(__add_emphasis_gray "${notice_msg}")"

    # build targeted wrapper command function name
    local wrapper_action_method="__run_action_${_TF_ACTION}"

    # Informal notice for current directory
    info "Running from \"${PWD}\""

    ### Check terraform workspace exists and is active
    ###############################################################################
    if [ "${_TF_ACTION}" != "workspace" ]; then  # don't validate workspace when running "workspace"
    if [ "${_TF_ACTION}" != "init" ]; then  # don't validate workspace when running "init"
    if [ "${_TF_ACTION}" != "fmt" ]; then   # don't validate workspace when running "fmt"
        __validate_tf_workspace
    fi
    fi
    fi

    # execute function
    $wrapper_action_method
}
