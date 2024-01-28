#!/usr/bin/env bash
#
# task.sh -- a terminal based todo-list manager
#
# author: BAUKE BLOMME <blomme.bauke@student.hogent.be>

#------------------------------------------------------------------------------
# Shell settings
#------------------------------------------------------------------------------

# TODO

# script stops when uninitialized variable is used or when command has exit status that isn't zero
set -eu

# set pipeline as failed when one of commands contained fails
set -eo pipefail




#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

settings_file=~/.taskrc;
logs_file=~/.tasklog
tempfile=tempfile.txt

#------------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------------

main() {
    # Check if the settings file exists, and create it if not
    if [ ! -e "$settings_file" ]; then
        create_settings_file;
    fi
    
    # Check if the logs file exists, and create it if not
    if [ ! -e "$logs_file" ]; then
        touch "$logs_file";
    fi
    
    
    # Evaluate the settings file
    # shellcheck source="$settings_file"
    # check if the settings file has bash syntax
    if [[ -n "$(bash -n "$settings_file" 2>&1)" ]]; then
        throw_error "The settings file $settings_file contains syntax errors" "$(bash -n "$settings_file" 2>&1)"
    fi
    # check if there are no problems loading the variables
    # (sometimes syntax can be okay but there's still errors, like when the file contains 1=1)
    if [[ -n "$(source "$settings_file" 2>&1)" ]]; then
        throw_error "The settings file $settings_file contains syntax errors" "$(source "$settings_file" 2>&1)"
    fi
    source "$settings_file"
    # if settings_file doesn't contain required values, add standard values
    complete_settings;
    
    
    # Check if arguments are present. If not, assume "help" was meant
    # Using a case statement, interpret the command (first argument) and any
    # other options or arguments, and call the appropriate function
    case "$#" in
        0)
        usage;;
        *)
            case "$1" in
                "help")
                    usage
                ;;
                "dump")
                    dump
                ;;
                "edit")
                    edit
                ;;
                "list-contexts")
                    list_contexts
                ;;
                "list-tags")
                    list_tags
                ;;
                "overdue")
                    overdue
                ;;
                "edit-settings")
                    edit_settings
                ;;
                "list-settings")
                    list_settings
                ;;
                "add")
                    add "$@"
                ;;
                "done")
                    delete_task "$@"
                ;;
                "search")
                    search "$@"
                ;;
                *)
                    throw_error "$1 is not a valid argument" "Tried calling function with invalid argument $1"
                ;;
            esac
        ;;
    esac
}

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------
# The functions are ordered alphabetically

# Usage: add "TASK"
# Adds a task to the task file and responds with the task ID.
add() {
    # check if there's an argument
    if [ "$#" -lt 2 ]; then
        throw_error "Missing description" "Tried adding empty task."
    fi
    # get the ID for the task
    nextID=$(get_next_task_id);
    
    # check if date is correct, if there is one
    check_date "${@:2}" "0";
    
    # add the task to the task file
    args=("${@:2}")
    args_string="${args[*]}"
    echo -e "$nextID\t$args_string" >> "$TASK_FILE"
    
    
    
    log_action "Created Task $nextID"
    # return ID
    echo "Created Task $nextID"
}


# Usage: check if date is valid
# for adding tasks and for checking the task file.
# if the date is faulty and if last param is 0, stop the program, if not, return that the date is faulty
check_date() {
    datum=$(echo "${@:1:$#-1}" | grep -Eo "[0-9]+-[0-9]+-[0-9]+" || echo "")
    if [ -n "$datum" ]; then
        # check if the format is correct
        if ! date --date="$datum" &>/dev/null; then
            if [ "${!#}" -eq 0 ]; then
                throw_error "Invalid date: $datum" "Tried adding task with invalid date: $datum"
            else echo False
            fi
        fi
    fi
}

# Usage: complete the settings file
# If task_file or task_editor are not present in the settings file, add the standard values
complete_settings() {
    if ! grep -q "TASK_FILE" "$settings_file"; then
        echo "TASK_FILE=~/.tasks" >> "$settings_file"
        log_action "TASK_FILE standard value has been added to settings file $settings_file"
    fi
    if ! grep -q "TASK_EDITOR" "$settings_file"; then
        vim_location=$(which vim);
        echo -e "TASK_EDITOR=$vim_location" >> "$settings_file";
        log_action "TASK_EDITOR standard value has been added to settings file $settings_file"
    fi
}

# Usage: create_settings_file
# Creates the settings file with default values
create_settings_file() {
    # don't hardcode the absolute path to vim
    vim_location=$(which vim);
    echo -e "TASK_FILE=~/.tasks\nTASK_EDITOR=$vim_location" > "$settings_file";
    log_action "$settings_file created"
    
}

# Usage: delete_task ID
# Asks for confirmation and then removes the task with the given ID from the
# task file.
delete_task() {
    # check if has one argument
    if [ "$#" -ne 2 ]; then
        throw_error "Needs exactly one argument" "Tried passing "$#" arguments into delete_task()"
    fi
    # check if task exists
    task=$(cat $TASK_FILE | grep "^$2[^0-9]" || echo "")
    if [ -n "$task" ]; then
        selection=0;
        while [ "$selection" -eq 0 ]; do
            read -p "Delete Task $task [y/n]? " okay
            case "$okay" in
                "y")
                    # mv "$tempfile" "$TASK_FILE"
                    sedstring="/$task/d"
                    sed -i "$sedstring" "$TASK_FILE"
                    selection=1
                ;;
                "n")
                    exit 0;
                ;;
                *)
                    echo "Invalid option $okay. Enter 'y' or 'n'."
                ;;
            esac
        done
    else
        throw_error "Task $2 doesn't exist" "Tried deleting unexisting task $2"
    fi
}

# Usage: dump
# Dumps the task file contents to stdout.
dump() {
    ensure_task_file;
    cat "$TASK_FILE";
    # not logging this action because it doesn't really affect anything
}

# Usage: edit
# Opens the task file in the editor specified in the settings file.
edit() {
    ensure_task_file;
    log_action "editor opened $TASK_FILE, file may be edited"
    "$TASK_EDITOR" "$TASK_FILE";
}

# Usage: edit settings file
# opens file in selected editor to edit it
edit_settings() {
    log_action "editor opened $settings_file, file may be edited"
    exec "$TASK_EDITOR" "$settings_file"
}

# Usage: Ensure the existence and syntax of a task file
# Check the syntax of a task file. If there are incorrect lines, give the option
# to fix them manually or remove them. If the task file doesn't exist, create a new empty one
ensure_task_file() {
    # task file needs to exist
    if [ ! -e "$TASK_FILE" ]; then
        touch "$TASK_FILE";
    else
        :
        # TODO id's have to be present
        # TODO id's need to be unique
        # TODO no duplicate contexts in one task
        # date in correct format
        faulty_tasks=()
        while IFS= read -r line; do
            if [ "$(check_date "$line" "1")" == "False" ]; then
                id="$(echo "$line" | grep -oE "^[0-9]+")"
                faulty_tasks+=("$id")
                echo "task "$id" has incorrect date"
            fi
        done < $TASK_FILE
        if [ ${#faulty_tasks[@]} -gt 0 ]; then
            echo -e "[1]\tRemove incorrect dates"
            echo -e "[2]\tRemove tasks with incorrect dates"
            echo -e "[3]\tCorrect dates manually"
            read -p "Choose option 1 or 2: " method
            selection=0
            while [ "$selection" -eq 0 ]; do
                case $method in
                    1)
                        remove_dates "${faulty_tasks[*]}"
                        selection=1
                    ;;
                    2)
                        remove_tasks "${faulty_tasks[*]}"
                        selection=1;
                    ;;
                    *)
                        echo "Invalid option $method. Please choose '1' or '2'"
                    ;;
                esac
            done
        fi
    fi
}

# Usage: get_next_task_id
# Looks in the task file for the next available task ID (an integer starting at
# 1) and prints it. If a task was previously deleted, its ID may be reused.
get_next_task_id() {
    # read all ID's from file, sort them for later
    IDs=$(grep -Eo "^[0-9]+" "$TASK_FILE" | sort -n );
    
    
    # Find the lowest integer not in the existing IDs
    nextID=1
    for id in $IDs; do
        if [ "$id" -eq "$nextID" ]; then
            ((nextID++));
        else
            break;
        fi
    done
    log_action "Found Next ID $nextID"
    echo "$nextID";
}

# Usage: list_contexts
# Lists all contexts in the task file with the number of tasks for each.
list_contexts() {
    list_delim "@";
}

list_delim() {
    ensure_task_file;
    # find all contexts, per context, count lines with matching grep
    cat "$TASK_FILE" | grep -oE "$1[^ ]+" | sort | uniq -c
}

# Usage: list settings
# Print the settings file to stdout
list_settings() {
    cat "$settings_file";
}

# Usage: list_tags
# List all tags in the task file (even if multiple tags are used in a single
# task) alphabetically.
list_tags() {
    list_delim "#";
}

# Usage: log actions in log file
# called by functions after propper execution
log_action() {
    echo -e "$(date +"%d/%m/%Y-%H:%M:%S")\tSUCCES\t$1" >> "$logs_file"
}

# Usage: overdue
# Lists all tasks with a deadline (in format yyyy-mm-dd) in the past.
overdue() {
    ensure_task_file;
    tasks_with_dates="$(cat "$TASK_FILE" | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}")"
    while IFS= read -r task; do
        taskdate="$(echo "$task" | grep -Eo "[0-9]{4}-[0-9]{2}-[0-9]{2}")"
        dateseconds=$(date -d "$taskdate" +%s)
        current_seconds=$(date +%s)
        if [ "$dateseconds" -lt "$current_seconds" ]; then 
        echo "$task"
        fi
    done <<< "$tasks_with_dates"
}

# Usage: remove the date from a list of tasks, given the id's
# used for removing faulty dates
remove_dates() {
    faulty_ids=($1)  # Split space-separated IDs
    cp "$TASK_FILE" "$tempfile"
    for id in "${faulty_ids[@]}"; do
        sedstring="s/\(^$id.*[^0-9]\)[0-9]\+-[0-9]\+-[0-9]\+ */\1/g"
        sed -i "$sedstring" "$tempfile"
    done
    sed -i '/^$/d' "$tempfile"
    cat "$tempfile"
    selection=0
    while [ "$selection" -eq 0 ]; do
        read -p "Changes Okay [y/n]? " okay
        case "$okay" in
            "y")
                mv "$tempfile" "$TASK_FILE"
                selection=1
            ;;
            "n")
                ensure_task_file;
                selection=1
            ;;
            *)
                echo "Invalid option $okay. Enter 'y' or 'n'."
            ;;
        esac
    done
}



# Usage
#
remove_tasks() {
    faulty_ids=($1)  # Split space-separated IDs
    cp "$TASK_FILE" "$tempfile"
    for id in "${faulty_ids[@]}"; do
        sedstring="s/^$id.*[^0-9][0-9]\+-[0-9]\+-[0-9]\+ *//g"
        sed -i "$sedstring" "$tempfile"
    done
    sed -i '/^$/d' "$tempfile"
    cat "$tempfile"
    selection=0
    while [ "$selection" -eq 0 ]; do
        read -p "Changes Okay [y/n]? " okay
        case "$okay" in
            "y")
                mv "$tempfile" "$TASK_FILE"
                selection=1
            ;;
            "n")
                ensure_task_file;
                selection=1
            ;;
            *)
                echo "Invalid option $okay. Enter 'y' or 'n'."
            ;;
        esac
    done
}

# Usage: search PATTERN
# Searches the task file for tasks matching PATTERN and prints them to stdout.
search() {
    if [ "$#" -ne 2 ]; then
        throw_error "Search needs exactly one argument" "Tries calling Search with $# arguments"
    fi
    cat "$TASK_FILE" | grep "$2"
    
}

# Usage: throw errors, give info that needs to be printed and pass the error for the logs
# general formatting for the used errors in the code
throw_error() {
    echo -e "Error: $1.\nTry ${0} \"help\" for usage information." >&2
    echo -e "$(date +"%d/%m/%Y-%H:%M:%S")\tERROR\t$2" >> "$logs_file"
    exit 1;
}

# Usage: usage
# Prints usage information for this script.
usage() {
cat << _EOF_
Usage ${0} COMMAND [ARGUMENTS]...

----- TASKS -----

add 'TASK DESCRIPTION'
             add a task
done ID
             mark task with ID as done
dump
             show all tasks, including task ID
edit
             edit the task file
list-contexts
             show all contexts (starting with @)
list-tags
             show all tags (starting with #)
overdue
             show all overdue tasks
search 'PATTERN'
             show all tasks matching (regex) PATTERN

----- SETTINGS -----

edit-settings
             edit the settings file
list-settings
             show all settings in the settings-file

----- TASK FORMAT -----

A task description is a string that may contain the following elements:

- @context,   i.e. a place or situation in which the task can be performed
              (See Getting Things Done) e.g. @home, @campus, @phone, @store, ...
- #tag        tags, that can be used to group tasks within projects,
              priorities, etc. e.g. #linux, #de-prj, #mit (most important
              task), ... Multiple tags are allowed!
- yyyy-mm-dd  a due date in ISO-8601 format

In the task file, each task will additionaly be assigned a unique ID, an
incrementing integer starting at 1.
_EOF_
    exit 0;
    
}

main "${@}"