require_relative "models"

# This module extends the base REST controller to support Action Cable Channels. If the controller
# is associated to a specific model, then we can even support broadcasting table/record updates.
#
# The general idea is to dynamically construct a namespaced `::Channel` class to implement the
# channel functionality.
#
# For controllers associated to models, we will support 2 types of updates:
#  - Table Updates: Table updates will notify the subscriber when ANY record of a table is modified,
#    whether it's a create, update, or delete. The notification will not include details on the
#    specific record or records affected.
#  - Record Updates: Record updates will notify the subscriber when a record is created, updated, or
#    deleted, and will include the entire record and the action that was performed.
#    TODO: this must be constrained to the records in `get_recordset`.
#
module RESTFramework::ChannelControllerMixin
end
