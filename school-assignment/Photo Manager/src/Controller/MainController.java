package Controller;

import Model.Database;
import Model.DatabaseManager;
import View.View;
import View.ViewAgent;


/**
 * A abstract controller
 */

abstract class MainController {
    /**
     * the singleton databaseManager of the application
     */
    DatabaseManager dbManager = DatabaseManager.getDbManager();

    /**
     * the singleton main view of the application
     */
    View mainView = View.getView();

    /**
     * the singleton database of the application
     */
    Database database = Database.getDatabase();

    /**
     * the singleton viewAgent object that responsible to refresh and update the GUI
     */
    ViewAgent viewAgent = ViewAgent.getViewAgent();

}
