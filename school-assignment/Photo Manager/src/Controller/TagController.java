package Controller;

import Model.Photo;
import Model.Tag;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.scene.control.TextField;

import java.util.ArrayList;
import java.util.List;

/**
 * a controller that control all tag related events such as add existing tags, choose old set of tags
 * TagController is a observer for the databaseManager model
 *
 */
public class TagController extends MainController implements EventHandler<ActionEvent> {
    /**
     * a singleton tagController object for this application
     */
    private static TagController tagController = new TagController();

    /**
     * get the singleton tagController object
     *
     * @return the only tagController object
     */
    public static TagController getTagController() {
        return tagController;
    }

    @Override
    public void handle(ActionEvent event) {
        // the event source
        Object source = event.getSource();
        Photo activePhoto = mainView.getCurrentActivePhoto();
        List<Tag> selectedTags = new ArrayList<>(mainView.getSelectedTags());
        if (mainView.getAddNewTag() == source) {
            // get the input text
            TextField textField = mainView.getNewTagTextField();
            String inputString = textField.getText();
            addNewTagEventHandler(inputString);
            // clear the input text
            textField.setText("");
        } else if (mainView.getDeleteTag() == source) {
            deleteTagsEventHandler(activePhoto, selectedTags);
        } else if (mainView.getAddTag() == source) {
            addExistingTagsEventHandler(activePhoto, selectedTags);
        } else if (mainView.getChooseOldTags() == source) {
            chooseOldTagsEventHandler(activePhoto);
        }
    }

    /**
     * format the string with "@" sign if the tagString does not have it
     *
     * @param tagString the tag name that need to be modified if necessary
     * @return the modified tag name with the "@" symbol in front
     */
    private String formattedTagString(String tagString) {
        if (!tagString.contains("@"))
            tagString = "@" + tagString;
        return tagString;
    }

    /**
     * add new tags independent from any images to the program
     */
    private void addNewTagEventHandler(String inputString) {
        if (inputString.length() > 0) {
            // create a new Tag
            Tag newTag = new Tag(formattedTagString(inputString));
            // update the current existing tag listView
            database.addCurrentExistingTag(newTag);
        }
    }


    /**
     * add selected tags to current active photo object and update the list views
     *
     * @param activePhoto  the current selected photo in the GUI.
     * @param selectedTags a list of tags that are selected by the user
     */
    private void addExistingTagsEventHandler(Photo activePhoto, List<Tag> selectedTags) {
        if (activePhoto != null && selectedTags.size() > 0) {
            // add each tag into the photo object
            dbManager.addTags(activePhoto, selectedTags);
        } else
            viewAgent.updateStatusMessage("Please select a photo and tags in order to add");
    }

    /**
     * delete selected tags from the current active photo object if the there exist a selected photo
     * otherwise, delete the tags from the database
     *
     * @param activePhoto  the current selected photo in the GUI.
     * @param selectedTags a list of tags that are selected by the user
     */
    private void deleteTagsEventHandler(Photo activePhoto, List<Tag> selectedTags) {
        if (selectedTags.size() > 0 && activePhoto != null) {
            dbManager.deleteTags(activePhoto, selectedTags);
        } else
            viewAgent.updateStatusMessage("Please select a photo and tags before you add");
    }

    /**
     * add back the old tag sets to the current active photo
     * @param activePhoto the current selected photo object
     */
    private void chooseOldTagsEventHandler(Photo activePhoto) {
        List<Tag> tags = mainView.getSelectedOldTagSet();
        if (activePhoto != null && tags != null) {  // the photo exist and the user chose a a set of old tags
            // get the current active photo and replace all the tags with the selected old tag set
            List<Tag> oldTagSet = new ArrayList<>(tags);
            dbManager.replaceAllTags(activePhoto, oldTagSet);
            // Since some of the tags may not exist in the database, we need to take the old tag set and add it all back
            for (Tag oldTag : oldTagSet) {
                database.addCurrentExistingTag(oldTag);
            }
        } else
            viewAgent.updateStatusMessage("Please choose a photo and a old set of tags from the left");
    }
}
