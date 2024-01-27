#!/usr/bin/env bash
#
# task.sh -- a terminal based todo-list manager
#
# author: BAUKE BLOMME <blomme.bauke@student.hogent.be>

#------------------------------------------------------------------------------
# Shell settings
#------------------------------------------------------------------------------

# TODO

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

settings_file=~/.taskrc;
logs_file=~/.tasklog

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
    # shellcheck source=/dev/null
    # check if the settings file has bash syntax
    report_errors $(bash -n "$settings_file" 2>&1);
    # check if there are no problems loading the variables
    # (sometimes syntax can be okay but there's still errors, like when the file contains 1=1)
    report_errors $(source "$settings_file" 2>&1);
    source "$settings_file"
    # if settings_file doesn't contain required values, add them
    complete_settings;
    
    # Check if arguments are present. If not, assume "help" was meant
    # Using a case statement, interpret the command (first argument) and any
    # other options or arguments, and call the appropriate function
    case "$#" in
        0)
        usage;;
        1)
            case "$1" in
                "help")
                    usage
                ;;
                "edit-settings")
                    exec "$TASK_EDITOR" "$settings_file"
                ;;
                "list-settings")
                    cat "$settings_file"
                ;;
            esac
        ;;
        *)
            
    esac
    
    
}

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------
# The functions are ordered alphabetically

# Usage: add "TASK"
# Adds a task to the task file and responds with the task ID.
add() {
    echo "add moet nog geïmplementeerd worden"
}

# Usage: complete the settings file
# If task_file or task_editor are not present in the settings file, add the standard values
complete_settings() {
    if ! grep -q "TASK_FILE" "$settings_file"; then
        echo "TASK_FILE=~/.tasks" >> "$settings_file"
    fi
    if ! grep -q "TASK_EDITOR" "$settings_file"; then
        vim_location=$(which vim);
        echo -e "TASK_EDITOR=$vim_location" >> "$settings_file";
    fi
}

# Usage: create_settings_file
# Creates the settings file with default values.
create_settings_file() {
    # don't hardcode the absolute path to vim
    vim_location=$(which vim);
    echo -e "TASK_FILE=~/.tasks\nTASK_EDITOR=$vim_location" > "$settings_file";
}

# Usage: check for errors in the settings file
# if there are errors in the syntax or while loading, thise are handled by this function
report_errors() {
    if [[ -n $1 ]]; then
        echo -e "The settings file $settings_file contains syntax errors.\nPlease check $logs_file for more detailed information."
        echo -e "$(date +"%d/%m/%Y-%H:%M:%S")\t$1\n" >> "$logs_file"
        exit 1;
    fi
}

# Usage: delete_task ID
# Asks for confirmation and then removes the task with the given ID from the
# task file.
delete_task() {
    echo "delete_task moet nog geïmplementeerd worden"
}

# Usage: dump
# Dumps the task file contents to stdout.
dump() {
    echo "dump moet nog geïmplementeerd worden"
}

# Usage: edit
# Opens the task file in the editor specified in the settings file.
edit() {
    echo "edit moet nog geïmplementeerd worden"
    
}

# Usage: get_next_task_id
# Looks in the task file for the next available task ID (an integer starting at
# 1) and prints it. If a task was previously deleted, its ID may be reused.
get_next_task_id() {
    echo "get_nect_task_id moet nog geïmplementeerd worden"
    
}

# Usage: list_contexts
# Lists all contexts in the task file with the number of tasks for each.
list_contexts() {
    echo "list_contexts moet nog geïmplementeerd worden"
    
}

# Usage: list_tags
# List all tags in the task file (even if multiple tags are used in a single
# task) alphabetically.
list_tags() {
    echo "list_tags moet nog geïmplementeerd worden"
    
}

# Usage: overdue
# Lists all tasks with a deadline (in format yyyy-mm-dd) in the past.
overdue() {
    echo "overdue moet nog geïmplementeerd worden"
    
}

# Usage: search PATTERN
# Searches the task file for tasks matching PATTERN and prints them to stdout.
search() {
    echo "search moet nog geïmplementeerd worden"
    
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