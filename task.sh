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

settings_file=

#------------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------------

main() {
    # Check if the settings file exists, and create it if not
    
    # Evaluate the settings file
    # shellcheck source=/dev/null
    source "${settings_file}"
    
    # Check if arguments are present. If not, assume "help" was meant
    if [ "$#" -eq 0 ]; then
        usage;
        exit 0;
    fi
    
    # Using a case statement, interpret the command (first argument) and any
    # other options or arguments, and call the appropriate function
    
}

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------
# The functions are ordered alphabetically

# Usage: add "TASK"
# Adds a task to the task file and responds with the task ID.
add() {
    :
}

# Usage: create_settings_file
# Creates the settings file with default values.
create_settings_file() {
    :
}


# Usage: delete_task ID
# Asks for confirmation and then removes the task with the given ID from the
# task file.
delete_task() {
    :
}

# Usage: dump
# Dumps the task file contents to stdout.
dump() {
    :
}

# Usage: edit
# Opens the task file in the editor specified in the settings file.
edit() {
    :
}

# Usage: get_next_task_id
# Looks in the task file for the next available task ID (an integer starting at
# 1) and prints it. If a task was previously deleted, its ID may be reused.
get_next_task_id() {
    :
}

# Usage: list_contexts
# Lists all contexts in the task file with the number of tasks for each.
list_contexts() {
    :
}

# Usage: list_tags
# List all tags in the task file (even if multiple tags are used in a single
# task) alphabetically.
list_tags() {
    :
}

# Usage: overdue
# Lists all tasks with a deadline (in format yyyy-mm-dd) in the past.
overdue() {
    :
}

# Usage: search PATTERN
# Searches the task file for tasks matching PATTERN and prints them to stdout.
search() {
    :
}

# Usage: usage
# Prints usage information for this script.
usage() {
cat << _EOF_
Usage ${0}: 
Usage: ./task.sh COMMAND [ARGUMENTS]...

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

TASK FORMAT

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
}

main "${@}"