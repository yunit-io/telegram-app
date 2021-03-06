import QtQuick 2.4
import Ubuntu.Components 1.3
import AsemanTools 1.0
import TelegramQML 1.0
import QtQuick.Window 2.0

Item {
    id: message_action
    width: 100
    height: column.height + units.gu(2)

    property Message message
    property MessageAction action: message.action
    property User user: telegramObject.user(action.userId)
    property User fromUser: telegramObject.user(message.fromId)
    property FileLocation imgLocation: action.photo.sizes.first? action.photo.sizes.first.location : telegramObject.nullLocation

    property bool hasAction: action.messageActionEnum != MessageAction.Empty

    onImgLocationChanged: {
        if(imgLocation == telegramObject.nullLocation)
            return

        telegramObject.getFile(imgLocation)
    }

    Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: hasAction

        Label {
            id: actionText
            anchors.horizontalCenter: parent.horizontalCenter
            width: Screen.width * 0.85
            horizontalAlignment: Text.AlignHCenter
            fontSize: "small"
            color: theme.palette.normal.backgroundSecondaryText
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            textFormat: Text.RichText
            text: {
                var res = ""
                var userName = user.firstName + " " + user.lastName
                var fromUserName = fromUser.firstName + " " + fromUser.lastName
                userName = userName.trim()
                fromUserName = fromUserName.trim()
                if (fromUserName.length == 0)
                    fromUserName = i18n.tr("Deleted Account")

                switch(action.messageActionEnum) {
                case MessageAction.ChatCreate:
                    if (action.title == "Secret Chat") {
                        if (user.id == telegramObject.me)
                            res = i18n.tr("You have invited %1 to join a secret chat.").arg(fromUserName)
                        else
                            res = i18n.tr("%1 invited you to join a secret chat.").arg(fromUserName)
                    } else {
                        if (fromUser.id == telegramObject.me)
                            res = i18n.tr("You created the group")
                        else
                            res = i18n.tr("<b>%1</b> created the group").arg(fromUserName)
                    }
                    break

                case MessageAction.ChatAddUser:
                    {
                        var singleUserId = action.userId
                        if (singleUserId == 0 && action.users.length == 1)
                            singleUserId = action.users[0]
                        if (singleUserId != 0)
                        {
                            var whoUser = telegramObject.user(singleUserId)
                            if (whoUser == null)
                            {
                                res = "Unknown error, report this to Github plz!"
                                break;
                            }
                            var whoUserName = whoUser.firstName + " " + whoUser.lastName
                            whoUserName = whoUserName.trim()
                            if (singleUserId == message.fromId)
                            {
                                if (isChannel && !chat.megaGroup)
                                    res = i18n.tr("You joined the channel")
                                else
                                {
                                    if (isChannel && chat.megaGroup)
                                        if (singleUserId == telegramObject.me)
                                            res = i18n.tr("You joined the group")
                                        else
                                            res = i18n.tr("<b>%1</b> joined the group").arg(fromUserName)
                                    else if (message.out)
                                        res = i18n.tr("You returned to the group")
                                    else
                                        res = i18n.tr("<b>%1</b> returned to the group").arg(fromUserName)
                                }
                            }
                            else
                            {
                                if (message.out)
                                    res = i18n.tr("You added <b>%1</b>").arg(whoUserName)
                                else if (singleUserId == telegramObject.me)
                                {
                                    res = i18n.tr("<b>%1</b> added you").arg(fromUserName)
                                }
                                else
                                    res = i18n.tr("<b>%1</b> added <b>%2</b>").arg(fromUserName).arg(whoUserName)
                            }
                        }
                        else
                        {
                            if (message.out)
                                res = i18n.tr("You added multiple users")
                            else
                                res = i18n.tr("<b>%1</b> added multiple users").arg(fromUserName)
                        }
                    }
                    break

                case MessageAction.ChatDeleteUser:
                    if (user.id == fromUser.id) {
                        // TRANSLATORS: %1 is the person, who left the group chat.
                        res = i18n.tr("<b>%1</b> left the group").arg(userName)
                    } else {
                        if (fromUser.id == telegramObject.me)
                            res = i18n.tr("You removed <b>%1</b>").arg(userName)
                        else if (user.id == telegramObject.me)
                            res = i18n.tr("<b>%1</b> removed you").arg(fromUserName)
                        else
                            res = i18n.tr("<b>%1</b> removed <b>%2</b>").arg(fromUserName).arg(userName)
                    }
                    break

                case MessageAction.ChatEditTitle:
                    var titleText = action.title.replace("\"", "")

                    if (fromUser.id == telegramObject.me)
                        res = i18n.tr("You changed the group name to %1").arg(titleText)
                    else {   
                        // TRANSLATORS: %1 is the person, who changed group name to title %2.
                        res = i18n.tr("<b>%1</b> changed the group name to %2").arg(fromUserName).arg(titleText)
                    }
                    break

                case MessageAction.ChatEditPhoto:
                    // TRANSLATORS: %1 is the person, who changed the group photo.
                    if (fromUser.id == telegramObject.me)
                        res = i18n.tr("You changed the group photo")
                    else
                        res = i18n.tr("<b>%1</b> changed the group photo").arg(fromUserName)
                    break

                case MessageAction.ChatDeletePhoto:
                    // TRANSLATORS: %1 is the person, who deleted the group photo.
                    if (fromUser.id == telegramObject.me)
                        res = i18n.tr("You removed the group photo")
                    else
                        res = i18n.tr("<b>%1</b> removed the group photo").arg(fromUserName)
                    break

                case MessageAction.ChatJoinedByLink:
                    if (fromUser.id == telegramObject.me)
                        res = i18n.tr("You joined the group via invite link")
                    else
                        res = i18n.tr("<b>%1</b> joined the group via invite link").arg(fromUserName)
                    break

                case MessageAction.Empty:
                    break;

                default:
                    break
                }

                return res
            }
        }

        Image {
            id: img
            anchors.horizontalCenter: parent.horizontalCenter
            width: units.gu(8)
            height: units.gu(10)
            sourceSize: Qt.size(width,width)
            source: {
                if(imgPath.length==0)
                    return ""
                else
                    return imgPath
            }
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            visible: imgPath.length != 0

            property string imgPath: imgLocation!=telegramObject.nullLocation? imgLocation.download.location : ""
        }
    }
}
