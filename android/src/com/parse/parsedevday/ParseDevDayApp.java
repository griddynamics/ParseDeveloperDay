package com.parse.parsedevday;

import com.ibeacons.LifecycleHandler;
import com.parse.Parse;
import com.parse.ParseObject;
import com.parse.PushService;
import com.parse.parsedevday.model.Favorites;
import com.parse.parsedevday.model.Room;
import com.parse.parsedevday.model.Slot;
import com.parse.parsedevday.model.Speaker;
import com.parse.parsedevday.model.Talk;
import com.parse.parsedevday.util.FavoritesNotificationScheduler;
import com.parse.parsedevday.view.MainActivity;

import android.app.Application;

/**
 * The main app class mostly handles setting up global state, such as Parse keys.
 */
public class ParseDevDayApp extends Application {
  public void onCreate() {
    registerActivityLifecycleCallbacks(new LifecycleHandler());
    // Register subclasses for various kinds of Parse Objects.
    ParseObject.registerSubclass(Room.class);
    ParseObject.registerSubclass(Slot.class);
    ParseObject.registerSubclass(Speaker.class);
    ParseObject.registerSubclass(Talk.class);

    // Initialize Parse with the application ID and client key.
    Parse.initialize(this, "hSOvtKymudukuSdrlkqzKMcCna9JNgNUpQegnJBL",
        "I9pvaNaxCAMRMMTpSkM7MXd5WRLibZY5HokHmvUL");

    // Enable the Parse push notification service for remote pushes.
    PushService.setDefaultPushCallback(this, MainActivity.class);

    // Setup the listener to handle local notifications for when talks start.
    Favorites.get().addListener(new FavoritesNotificationScheduler(this));

    // Read in the favorites from the local disk on this device.
    Favorites.get().findLocally(this);
  }
}
