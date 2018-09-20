package Controller;

import Model.Photo;
import Model.Tag;
import javafx.collections.ObservableList;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.stage.DirectoryChooser;

import java.awt.*;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * a controller that control all the file related events happened in the GUI
 * FileController is a observer for database model
 */
public class FileController extends MainController implements EventHandler<ActionEvent> {

    /**
     * a singleton fileController object for this application
     */
    private static FileController fileController = new FileController();

    /**
     * get the singleton fileController object
     *
     * @return the only fileController object
     */
    public static FileController getFileController() {
        return fileController;
    }

    /**
     * A method that handle which event handler to execute
     * @param event the event object comes from the GUI
     */
    @Override
    public void handle(ActionEvent event) {
        // the event source
        Object source = event.getSource();
        Photo photo = mainView.getCurrentActivePhoto();
        if (mainView.getLoadImages() == source) {
            viewAgent.updateStatusMessage("You can also drag and drop photos to above");
            File allFiles = new DirectoryChooser().showDialog(mainView.getSourceWindow());
            loadImagesEventHandler(allFiles);
        } else if (mainView.getOpenFolder() == source) {
            openFolderEventHandler(photo);
        } else if (mainView.getMoveDirectory() == source) {
            moveFileEventHandler(photo);
        } else if (mainView.getLog() == source) {
            logEventHandler();
        }
    }


    /**
     * load all the image objects into database and display all image's name onto the list views in GUI
     */
    private void loadImagesEventHandler(File allFiles) {
        if (allFiles != null) { // make sure the user select the folder
            List<File> files = Arrays.asList(allFiles.listFiles());
            // start to load all the images and display to the listView
            loadImages(files, mainView.getImgInDirectory().getItems(), true);
        }
    }

    /**
     * get all the image files EVERYWHERE in the directory if recursive is true
     * get all the image files UNDER the directory if recursive is false
     *
     * @param allFiles  a list of all file objects under the root directory
     * @param recursive if this function need to be recursively called
     */
    void loadImages(List<File> allFiles, ObservableList<Photo> photos, boolean recursive) {
        for (File file : allFiles) {
            if (file.isFile() && isImageFile(file)) {
                Photo photo = getPhoto(file);
                if (!photos.contains(photo)) {
                    photos.add(photo);
                }
            } else if (file.isDirectory() && recursive) {
                // recursively call the directory
                loadImages(Arrays.asList(file.listFiles()), photos, true);
            }
        }
    }

    /**
     * get the photo from the database if it exists otherwise return a new photo object
     *
     * @param imgFile the image file in the selected directory
     * @return the photo object either from the database or newly created
     */
    private Photo getPhoto(File imgFile) {
        Photo photo;
        String path = imgFile.getPath();
        if (database.hasPhoto(path)) { // get the image from the database
            photo = database.getPhoto(path);  // get the same object
        } else {  // add a new image
            List<Tag> tagSet = extractTagSetsFromPhoto(imgFile);
            photo = new Photo(path, tagSet);
            database.addPhoto(photo);
            dbManager.addTags(photo, tagSet);  // add the tags to the photo and the database if unique
        }
        return photo;
    }

    /**
     * extract a list of tags for a particular img file
     *
     * @param imgFile the image file that need to extract
     * @return a list of tags that belong to the this image file
     */
    private List<Tag> extractTagSetsFromPhoto(File imgFile) {
        String name = imgFile.getName();
        List<Tag> tagSet = new ArrayList<>();
        int firstTagIndex = name.indexOf("@");
        if (firstTagIndex >= 0) {
            String[] tags = name.substring(firstTagIndex, name.lastIndexOf(".")).split(" ");
            for (String tagName : tags) {
                if (database.containTag(tagName))
                    tagSet.add(database.getTag(tagName));
                else
                    tagSet.add(new Tag(tagName));
            }
        }
        return tagSet;
    }

    /**
     * Assume the image is in the database
     * move the current active image file to a new directory that is selected by user
     */
    private void moveFileEventHandler(Photo photo) {
        if (photo != null) {
            // let the user choose the folder and set the new directory to the image object
            DirectoryChooser directoryChooser = new DirectoryChooser();
            File newFolder = directoryChooser.showDialog(mainView.getSourceWindow());
            if (newFolder != null) {
                String newPhotoPath = newFolder.getPath() + File.separator + photo.getNameWithExtension();
                photo.setDirectory(newPhotoPath); // update the image model information
                // update the list view directory
                viewAgent.refreshPhotoListViewByTag();
                viewAgent.refreshPhotoListViews();
                try {
                    openDir(photo.getFolderDirectory());
                } catch (IOException e) {
                    viewAgent.updateStatusMessage("Move file failed");
                }
            }
        } else {
            viewAgent.updateStatusMessage("No photo is selected");
        }
    }

    /**
     * open the folder directory of the active photo in system's browse window
     */
    private void openFolderEventHandler(Photo activePhoto) {
        // get the image directory that is currently displayed in the imageView window
        if (activePhoto != null) {
            String folderPath = activePhoto.getFolderDirectory();
            try {
                openDir(folderPath);
            } catch (IOException e) {
                viewAgent.updateStatusMessage("Invalid Directory");
            }
        } else {
            viewAgent.updateStatusMessage("No photo is selected");
        }
    }

    /**
     * open the log file for user to see if the corresponding button is clicked
     */
    private void logEventHandler() {
        try {
            openDir("nameLog.txt");
        } catch (IOException e) {
            mainView.getStatusMessage().setText("You have not change any name of the photos -> No log available");
        }
    }

    /**
     * open the folder according the directory give if it is a valid path
     *
     * @param directory the path to the folder
     */
    void openDir(String directory) throws IOException {
        // Reference: https://stackoverflow.com/questions/23176624/javafx-freeze-on-desktop-openfile-desktop-browseuri
        if (Desktop.isDesktopSupported()) {
            new Thread(() -> {
                try {
                    Desktop.getDesktop().open(new File(directory));
                } catch (IOException e) {
                    viewAgent.updateStatusMessage("Open folder failed");
                }
            }).start();
        }
    }

    /**
     * check if the file is a photo file or not
     * Note: This is a filter function to filter only image files
     *
     * @param file a file object to be checked
     * @return if this is a photo file
     */
    boolean isImageFile(File file) {
        String[] extensions = database.getAcceptableImageExtensions();
        for (String extension : extensions) {
            if (file.getName().toLowerCase().endsWith(extension)) {
                return true;
            }
        }
        return false;
    }
}
