# Be sure to restart your server when you modify this file.

# This file that contains all of application constants
# constanst_name = valuse


# layout names of views

LAYOUT_DEFAULT            = 'application'
LAYOUT_MAINTENANCE        = 'maintenance'
LAYOUT_BLANK              = 'blank'
LAYOUT_WATCHERCLI         = 'watchercli'

# list of maintenance menus

LIST_MAINTENANCE_MENUS    = [
                              { name: "General", items: [
                                { name: "Users", controller: "users", action: "index" },
                                { name: "Groups", controller: "groups", action: "index" },
                                { name: "Roles", controller: "roles", action: "index" }
                              ]},
                              { name: "Call Recording", items: [
                                { name: "Tags", controller: "tags", action: "index" },
                                { name: "Call Category", controller: "call_categories", action: "index" },
                                { name: "Phone Exts", controller: "phone_extensions", action: "index" },
                                { name: "Phone Numbers", controller: "phone_infos", action: "index" },
                                { name: "Call Export", controller: "export_calls", action: "index" },
                                { name: "Keywords", controller: "keywords", action: "index" }
                              ]},
                              { name: "Evaluation and Assignment", items: [
                                { name: "Assignment", controller: "evaluation_tasks", action: "index" },
                                { name: "Evaluation Forms", controller: "evaluation_plans", action: "index" },
                                { name: "Evaluation Question", controller: "evaluation_questions", action: "index" },
                                { name: "Document Template", controller: "document_templates", action: "index" },
                                { name: "Grade Setting", controller: "evaluation_grade_settings", action: "index" },
                                { name: "Auto Assessment Rule", controller: "auto_assessment_rules", action: "index" }
                              ]},
                              { name: "System and Logging", items: [
                                { name: "Configurations", controller: "configurations", action: "index", su: true },
                                { name: "Permissions", controller: "permissions", action: "index" },
                                { name: "Log", controller: "operation_logs", action: "index" },
                                { name: "Message Logs", controller: "message_logs", action: "index" },
                                { name: "Computer Logs", controller: "computer_logs", action: "index" },
                                { name: "Locked Sessions", controller: "web_sessions", action: "index" },
                                { name: "System Info", controller: "system_info", action: "index", su: true }
                              ]}
                            ]

APP_MODULES               = [
                              {
                                title: "Call Browser",
                                list: ["call_browser"]
                                },
                              {
                                title: "Evaluation",
                                list: ["evaluations", "evaluation_plans", "evaluation_tasks", "evaluation_reports"]
                                },
                              {
                                title: "Transcription and Keyword",
                                list: ["search", "voice_logs.transcriptions", "voice_logs.keywords", "keywords"]
                                },
                              {
                                title: "Speech Analytics",
                                list: ["analytics"]
                              }
                            ]

# order by asc/desc

DB_ORDER_BY               = ['asc', 'desc']
DB_INIT_FLAG              = ''
DB_LOCKED_FLAG            = 'L'
DB_DELETED_FLAG           = 'D'
DB_HIDDEN_FLAG            = 'H'
DB_TEMP_FLAG              = 'T'

MAX_ORDERNO_INT           = 999999

# role's name

ROLE_ADMIN_GROUP          = ['Administrator']

# table/model variables

STATE_ACTIVE               = 'A'
STATE_SUSPEND              = 'S'
STATE_DELETE               = 'D'

SYS_USTATE                 = ':ustate'
SYS_SEX                    = ':sex'

VL_INBOUND                 = 'i'
VL_OUTBOUND                = 'o'

ROLE_DEFAULT_NAME          = nil

GROUP_SEQ_DELIMETER        = "."
GROUP_PATH_DELIMETER       = "-"

NO_AUTHEN_CONTROLLERS      = ["devise", "sessions", "webapi", "errors", "devise/sessions","keywords","watchercli"]
