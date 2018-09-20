package Controller;

import Model.Photo;
import Model.Tag;
import javafx.collections.ObservableList;
import javafx.event.EventHandler;
import javafx.scene.image.Image;
import javafx.scene.input.MouseEvent;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * a controller that control all the list view click events
 */
public class ListViewController extends MainController implements EventHandler<MouseEvent>{


    /**
     * a singleton listViewController object for this application
     */
    private static ListViewController listViewController = new ListViewController();

    /**
     * get the singleton listViewController object
     * @return the only listViewController object
     */
    public static ListViewController getListViewController(){
        return listViewController;
    }

    @Override
    public void handle(MouseEvent event) {
        Object source = event.getSource();
        if (source == mainView.getImgInDirectory()) {
            getImgInDirectoryHandler();
        } else if (source == mainView.getAvailableTags()){
            displayImagesByTagEventHandler();
        } else if (source == mainView.getImgsFromTag()) {
            getImgsByTagHandler();
        }
    }

    /**
     * handle click event for the listview that display all images ANYWHERE in the directory
     */
    private void getImgInDirectoryHandler() {
        Photo activePhoto = mainView.getSelectedImgInDirectory();
        if (activePhoto != null) {
            outputImageToViewport(activePhoto);
        }
    }

    /**
     * handle click event for the listview that display all images ANYWHERE in the directory
     */
    private void getImgsByTagHandler() {
        Photo activePhoto = mainView.getSelectedImgUnderDirectory();
        if (activePhoto != null) {
            outputImageToViewport(activePhoto);
        }
    }

    /**
     * display all the photos that related to the selected tags
     */
    private void displayImagesByTagEventHandler(){
        viewAgent.refreshPhotoListViewByTag();
    }

    /**
     * set the image viewport to display the image according to the img directory
     *
     * @param img the image directory
     */
    private void outputImageToViewport(Photo img) {
        File file = new File(img.getDirectory());
        Image image = new Image(file.toURI().toString());
        // update the view
        mainView.displaySelectedImage(image);
        mainView.setCurrentActivePhoto(img);

        viewAgent.refreshOldTagListView();
        viewAgent.updateCurrentPhotoPath();
    }

}
