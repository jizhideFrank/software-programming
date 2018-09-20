package Model;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;

/**
 * serialize all data of this application before it is closed
 */
public class ApplicationSerializer {

    /**
     * the singleton serializer object to serialize all necessary data in this application
     */
    private static ApplicationSerializer applicationSerializer = new ApplicationSerializer();

    /**
     * get the singleton serializer object for this application
     * @return the singleton serializer object
     */
    public static ApplicationSerializer getSerializer() {
        return applicationSerializer;
    }

    /**
     * serialize the application
     *
     * @param obj              the object that need to be serialized
     * @param expectedFileName the expected file name
     */
    public void serialize(Object obj, String expectedFileName) {
        try {
            FileOutputStream fileOut = new FileOutputStream(expectedFileName + ".ser");
            ObjectOutputStream out = new ObjectOutputStream(fileOut);
            out.writeObject(obj);
            out.close();
            fileOut.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
