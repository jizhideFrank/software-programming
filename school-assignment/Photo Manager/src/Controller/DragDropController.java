package Controller;

import javafx.event.EventHandler;
import javafx.scene.image.Image;
import javafx.scene.input.DragEvent;
import javafx.scene.input.TransferMode;

import java.io.File;
import java.util.List;

public class DragDropController extends MainController implements EventHandler<DragEvent> {

    /**
     * a singleton dragDropController object for this application
     */
    private static DragDropController dragDropController = new DragDropController();

    /**
     * get the singleton dragDropController object
     *
     * @return the only dragDropController object
     */
    public static DragDropController getDragDropController() {
        return dragDropController;
    }

    /**
     * get the singleton fileController object as a helper to load photo data to the database
     */
    private FileController fileController = FileController.getFileController();

    @Override
    public void handle(DragEvent event) {
        if (event.getEventType() == DragEvent.DRAG_OVER) {
            dragOverEventHandler(event);
        }
        if (event.getEventType() == DragEvent.DRAG_DROPPED) {
            dropEventHandler(event);
            event.consume();
        }
    }

    /**
     * handle events that user drag files into the image window
     */
    private void dragOverEventHandler(DragEvent event) {
        if (event.getDragboard().hasFiles()) {
            event.acceptTransferModes(TransferMode.ANY);
        }
    }

    /**
     * handle events that user release their mouse button and drop the files into the image window
     */
    private void dropEventHandler(DragEvent event) {
        List<File> dropeddFiles = event.getDragboard().getFiles();
        if (dropeddFiles.size() != 0) {
            File imgFile = dropeddFiles.get(0);
            // set the image view
            if (fileController.isImageFile(imgFile)) {
                // set the photo as a active photo that is displayed in the application
                fileController.loadImages(dropeddFiles, mainView.getImgInDirectory().getItems(), false);
                mainView.setCurrentActivePhoto(database.getPhoto(imgFile.getPath()));
                Image img = new Image(imgFile.toURI().toString());
                mainView.displaySelectedImage(img);

                viewAgent.updateCurrentPhotoPath();
                viewAgent.refreshOldTagListView();
            }
        }
    }
}
