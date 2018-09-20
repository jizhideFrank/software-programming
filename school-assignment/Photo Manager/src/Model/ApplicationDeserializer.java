package Model;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;

/**
 * a deserializer of this application using singleton pattern
 * Deserialize will be complete before the program run
 * Retrieve Photo history from the last closure
 */
public class ApplicationDeserializer {
    /**
     * a singleton deserializer object that serialize the application data
     */
    private static ApplicationDeserializer applicationSerializer = new ApplicationDeserializer();

    /**
     * get the singleton deserializer object for this application
     *
     * @return the only deserializer object
     */
    public static ApplicationDeserializer getDeserializer() {
        return applicationSerializer;
    }

    /**
     * Deserialize the data in the application
     *
     * @param expectedFileName the file name
     * @return a deserialized database object if it exist, else null
     */
    public Object deserialize(String expectedFileName) {
        try {
            FileInputStream fileIn = new FileInputStream(expectedFileName + ".ser");
            ObjectInputStream in = new ObjectInputStream(fileIn);
            Database db = (Database) in.readObject();
            in.close();
            fileIn.close();
            return db;
        } catch (IOException | ClassNotFoundException i) {
            return null;
        }
    }

}
