#=============================================================================
#     FileName : gh-issue-preview.jq
#       Author : marslo
#      Created : 2026-05-18 20:40:00
#   LastChange : 2026-05-18 20:56:24
#=============================================================================

# ansi color helper
def c(code; text): "\u001b[" + code + "m" + text + "\u001b[0m";

# State (stateReason: COMPLETED, NOT_PLANNED, or null for open)
def state_bar:
  if .state == "OPEN" then c("32"; "● Open")
  elif .stateReason == "COMPLETED" then c("35"; "✔ Completed")       # purple - resolved/fixed
  elif .stateReason == "NOT_PLANNED" then c("2;37"; "⊘ Not Planned") # dim gray - won't fix
  elif .state == "CLOSED" then c("31"; "✖ Closed")                   # fallback
  else c("34"; "? " + .state) end;

# Author + timestamps
def meta_section:
  c("36"; "Author:") + " " + .author.login +
  "\n" +
  c("33"; "Created:") + " " + .createdAt +
  " " + c("35"; "•") + " " +
  c("33"; "Updated:") + " " + .updatedAt;

# Labels
def labels_section:
  ( .labels | map(.name) ) as $list |
  if ( $list | length ) > 0 then
    c( "33"; "Labels:" ) + " " + ( $list | map(c("0;34"; "[" + . + "]")) | join(" ") )
  else
    c( "2;3;37"; "Labels: N/A" )
  end;

# Assignees
def assignees_section:
  ( .assignees | map(.login) ) as $list |
  if ( $list | length ) > 0 then
    c( "36"; "Assignees:" ) + " " + ( $list | join(", ") )
  else
    c( "2;3;37"; "Assignees: N/A" )
  end;

# Milestone
def milestone_section:
  if .milestone != null and .milestone.title != null then
    c( "35"; "Milestone:" ) + " " + .milestone.title
  else
    c( "2;3;37"; "Milestone: N/A" )
  end;

# Comments summary
def comments_section:
  ( .comments | length ) as $count |
  c("36"; "Comments:") + " " + ( $count | tostring ) +
  if $count > 0 then
    "\n" +
    ( [ .comments[-3:][] |
        c("33"; .author.login) + ": " +
        ( .body | split("\n") | first |
          if length > 80 then .[:80] + "…" else . end
        )
      ] | join("\n") )
  else "" end;

# main output
state_bar + "\n" +
"\n" + meta_section +
"\n\n" + labels_section +
"\n" + assignees_section +
"\n" + milestone_section +
"\n\n" + comments_section +
"\n\n--------------------------------------\n" +
( .body | gsub("(?m)^[ \t]+"; "") | gsub("(?s)[ \t]*<!--.*?-->[ \t]*\n?"; "") )
