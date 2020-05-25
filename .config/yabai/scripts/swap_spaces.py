#!/usr/bin/python3
import subprocess
import json
import sys

proc_out = subprocess.run(['yabai', '-m', 'query', '--spaces'], stdout=subprocess.PIPE)
spaces_list = json.loads(proc_out.stdout.decode('utf-8'))
# label the spaces according to their current index
for x in spaces_list:
    subprocess.run(['yabai', '-m', 'space', str(x['index']), '--label', f"space-{x['index']}"])

# get the updated info
proc_out = subprocess.run(['yabai', '-m', 'query', '--spaces'], stdout=subprocess.PIPE)
spaces_list = json.loads(proc_out.stdout.decode('utf-8'))

spaces_to_switch = [
    (str(x['label']), str(x['display']))
    for x in spaces_list
    if x['visible'] == 1
]
assert len(spaces_to_switch) == 2
space_1_label, space_1_display = spaces_to_switch[0]
space_2_label, space_2_display = spaces_to_switch[1]

# move the spaces to the opposite displays
subprocess.run(['yabai', '-m', 'space', space_1_label, '--display', space_2_display])
subprocess.run(['yabai', '-m', 'space', space_2_label, '--display', space_1_display])

# reorder the spaces
subprocess.run(['yabai', '-m', 'space', space_1_label, '--move', space_2_label.split('-')[-1]])
subprocess.run(['yabai', '-m', 'space', space_2_label, '--move', space_1_label.split('-')[-1]])
