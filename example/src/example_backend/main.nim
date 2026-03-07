import nicp_cdk
import ./controller

proc migrate*() {.update.} = discard controller.migrate()