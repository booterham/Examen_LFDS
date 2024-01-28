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
                "list-logs")
                    list_logs "$@"
                ;;
                "list-settings")
                    list_settings
                ;;
                "add")
                    add "$@";
                ;;
                "done")
                    delete_task "$@";
                ;;
                "search")
                    search "$@";
                ;;
                "start-over")
                    delete_all_tasks;
                ;;
                *)
                    case "$#" in
                        1)
                            throw_error "$1 is not a valid argument" "Tried calling function with invalid argument $1";
                        ;;
                        *)
                            throw_error "$* are not a valid arguments" "Tried calling function with invalid arguments $*";
                        ;;
                    esac
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
        throw_error "Missing description" "Tried adding task without description."
    fi
    
    # TODO: check if task has description, not only a date or context
    #       only tags is allowed (e.g. task: 1  #carrots @store)
    
    # check if date is correct, if there is one
    check_date "${@:2}" "0";
    
    # get the ID for the task
    nextID=$(get_next_task_id);
    
    # add the task to the task file
    args=("${@:2}")
    args_string="${args[*]}"
    newTask="$nextID\t$args_string"
    echo -e "$newTask" >> "$TASK_FILE"
    
    # return ID
    log_action "Created Task $nextID" "Created Task $newTask"
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
        nano_location=$(which nano);
        echo -e "TASK_EDITOR=$nano_location" >> "$settings_file";
        log_action "TASK_EDITOR standard value has been added to settings file $settings_file"
    fi
}

# Usage: correct date manually
# per incorrect date, give a correct date or an empty string to remove the date
correct_date_manually() {
    faulty_ids=($@)  # Split space-separated IDs
    for id in "${faulty_ids[@]}"; do
        task="$(grep "^$id.*$" "$TASK_FILE")"
        olddate="$(echo "$task" | grep -oE "[0-9]+-[0-9]+-[0-9]+")"
        newdate_ok=0
        while [ "$newdate_ok" -eq 0 ]; do
            echo "Enter correct date for"
            read -p "    $task: " newdate
            if [ "$(check_date "$newdate" "1")" != "False" ]; then
                newdate_ok=1
            else
                log_action "Given faulty date $newdate while trying to correct date of task $task" "Wrong format, please enter a date in the following format: yyyy-mm-dd"
            fi
        done
        sed -i "s/\($id.*\)$olddate/\1$newdate/" "$TASK_FILE"
    done
    
}

# Usage: create_settings_file
# Creates the settings file with default values
create_settings_file() {
    # don't hardcode the absolute path to vim
    nano_location=$(which nano);
    echo -e "TASK_FILE=~/.tasks\nTASK_EDITOR=$nano_location" > "$settings_file";
    log_action "$settings_file created"
    
}

delete_all_tasks() {
    rm "$TASK_FILE";
    # no need to create the faile again, this is done by ensure_task_file
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
            read -p "Delete Task $task [Y/n]? " okay
            case "$okay" in
                "y"|"")
                    # mv "$tempfile" "$TASK_FILE"
                    sedstring="/$task/d"
                    sed -i "$sedstring" "$TASK_FILE"
                    log_action "Removed Task $task" "Removed Task $task"
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
    edit_file "$TASK_FILE"
    # log_action "editor opened $TASK_FILE, file may be edited"
    # "$TASK_EDITOR" "$TASK_FILE";
}

# Usage: edit settings file
# opens file in selected editor to edit it
edit_settings() {
    edit_file "$settings_file"
    # log_action "editor opened $settings_file, file may be edited"
    # "$TASK_EDITOR" "$settings_file"
}

edit_file() {
    log_action "editor opened $1, file may be edited"
    "$TASK_EDITOR" "$1"
}

ensure_ids() {
    echo "ensure id's needs to be implemented"
}

# Usage: Ensure the existence and syntax of a task file
# Check the syntax of a task file. If there are incorrect lines, give the option
# to fix them manually or remove them. If the task file doesn't exist, create a new empty one
ensure_task_file() {
    # task file needs to exist
    if [ ! -e "$TASK_FILE" ]; then
        touch "$TASK_FILE";
    else
        # TODO task needs at least some text or a tag (otherwise it contains useless info)
        
        # TODO id's have to be present and need tab between id and description
        ensure_ids;
        # TODO id's need to be unique
        unique_ids;
        # no duplicate contexts in one task
        remove_duplicate_contexts;
        # no duplicate tags in one task
        remove_duplicate_tags;
        # date in correct format
        faulty_tasks=()
        while IFS= read -r line; do
            if [ "$(check_date "$line" "1")" == "False" ]; then
                id="$(echo "$line" | grep -oE "^[0-9]+")"
                faulty_tasks+=("$id")
                faulty_date="$(echo "$line" | grep -oE "[0-9]+-[0-9]+-[0-9]+")"
                echo "task "$id" has incorrect date: $faulty_date"
            fi
        done < $TASK_FILE
        if [ ${#faulty_tasks[@]} -gt 0 ]; then
            echo -e "[d]\tRemove incorrect dates"
            echo -e "[t]\tRemove tasks with incorrect dates"
            echo -e "[e]\tCorrect manually"
            selection=0
            while [ "$selection" -eq 0 ]; do
                read -p "Choose option d, t or e: " method
                case $method in
                    d)
                        remove_faults -d "${faulty_tasks[*]}"
                        selection=1
                    ;;
                    t)
                        remove_faults -t "${faulty_tasks[*]}"
                        selection=1;
                    ;;
                    e)
                        correct_date_manually "${faulty_tasks[*]}";
                        selection=1;
                    ;;
                    *)
                        echo "Invalid option '$method'."
                    ;;
                esac
            done
            log_action "Task file contained faulty dates, this has now been fixed"
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
    echo "$(log_action "Found Next ID $nextID" "$nextID")"
}

# Usage: list_contexts
# Lists all contexts in the task file with the number of tasks for each.
list_contexts() {
    list_delim "@";
}

# Usage: list all words starting with specific delimiter
# Common code between list-tags and list-contexts
list_delim() {
    ensure_task_file;
    # find all contexts, per context, count lines with matching grep
    cat "$TASK_FILE" | grep -oE "$1[^ ]+" | sort | uniq -c
}


# Usage: list ligs
# list the last N logs. If N is greater than the amount of lines in the file,
# the whole file is written to stdout
list_logs() {
    if [ "$#" -eq 1 ]; then
        lines=10;
        elif [ "$#" -eq 2 ] && [[ "$2" =~ ^[0-9]+$ ]]; then
        # make sure N isn't greater than the amount of lines in the file
        lines=$(wc -l < "$logs_file")
        if [ "$2" -lt "$lines" ]; then
            lines="$2"
        fi
    else
        throw_error "list-logs recuires one integer argument" "Tried calling '$*', incorrect parameters."
    fi
    echo "SHOWING LAST $lines LINES FROM LOGS:"
    tail -n "$lines" "$logs_file"
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
    # if something needs to be written to stdout, do it here
    if [ "$#" -eq 2 ]; then
        echo -e "$2"
    fi
}

# Usage: overdue
# Lists all tasks with a deadline (in format yyyy-mm-dd) in the past.
overdue() {
    ensure_task_file;
    tasks_with_dates="$(cat "$TASK_FILE" | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}")"
    for task in "${tasks_with_dates[@]}"; do
        taskdate="$(echo "$task" | grep -Eo "[0-9]{4}-[0-9]{2}-[0-9]{2}")"
        dateseconds=$(date -d "$taskdate" +%s)
        currentsecconds=$(date +%s)
        [ "$dateseconds" -lt "$current_seconds" ] && echo "$1 is in the past." || echo "$1 is not in the past."
    done
}

remove_faults() {
    # Process command-line options
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d) # remove dates
                replace="\1"
                shift
            ;;
            -t) # remove whole tasks
                replace=""
                shift
            ;;
            *)
                break
            ;;
        esac
    done
    
    faulty_ids=($@)  # Split space-separated IDs
    cp "$TASK_FILE" "$tempfile"
    for id in "${faulty_ids[@]}"; do
        echo "id $id"
        sedstring="s/\(^$id.*[^0-9]\)[0-9]\+-[0-9]\+-[0-9]\+ */$replace/g"
        sed -i "$sedstring" "$tempfile"
    done
    sed -i '/^$/d' "$tempfile"
    cat "$tempfile"
    selection=0
    while [ "$selection" -eq 0 ]; do
        read -p "Changes Okay [Y/n]? " okay
        case "$okay" in
            "y"|"")
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


# Usage: remove all duplicate words with specified delimiter
# common code of remove_duplicate_tags and remove_duplicate_contexts
remove_duplicate_delim() {
    sed -i ":a; s/\($1[^[:space:]]\+ *\)\(.*\)\1/\1\2/g; ta" "$TASK_FILE";
}

# Usage: remove duplicate contexts
# there shouldn't be multiple of the same contexts in one task, this will mess with the count
# of contexts
remove_duplicate_contexts() {
    remove_duplicate_delim "@"
}

# Usage: remove duplicate tags
# there shouldn't be multiple of the same tag in one task, this will mess with the count
# of tags
remove_duplicate_tags() {
    remove_duplicate_delim "#"
}

# Usage: search PATTERN
# Searches the task file for tasks matching PATTERN and prints them to stdout.
search() {
    if [ "$#" -ne 2 ]; then
        throw_error "Search needs exactly one argument" "Tries calling Search with $# arguments"
    fi
    cat "$TASK_FILE" | grep --color "$2"
    
}

# Usage: throw errors, give info that needs to be printed and pass the error for the logs
# general formatting for the used errors in the code
throw_error() {
    echo -e "Error: $1.\nTry ${0} \"help\" for usage information." >&2
    echo -e "$(date +"%d/%m/%Y-%H:%M:%S")\tERROR\t$2" >> "$logs_file"
    exit 1;
}

# Usage: remove duplicate ids
unique_ids() {
    echo "uniqueids"
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
start-over
             delete all tasks

----- SETTINGS & LOGS -----

edit-settings
             edit the settings file
list-settings
             show all settings in the settings-file
list-logs N
             show last N logs

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