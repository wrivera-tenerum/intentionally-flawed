var cursor = db.getCollection('nodes').find({parent: "1436389178472619450271", type: "location", staged: true})
print("_id" + "," + "parent" + "," + "type" + "," + "created" +  "," + "name" + "," + "target" + "," + "staged")
while (cursor.hasNext()) {
    var record = cursor.next();
    var id = record._id.toString();
    var parent = record.parent;
    var type = record.type;
    var created = record.created.toString();
    var name = record.name.replace(',"+");
    var target = record.target;
    var staged = record.staged;
   
    print(id + ", " + parent + " , " + type + " ," + created + " ," + name + " , " + target + " ,"
    + staged)
}
