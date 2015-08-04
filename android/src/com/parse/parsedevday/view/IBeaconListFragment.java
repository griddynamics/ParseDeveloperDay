package com.parse.parsedevday.view;

import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.Toast;
import com.ibeacons.beaconinterface.IBeacon;
import com.ibeacons.lightbluebean.IBeaconManager;
import com.parse.FindCallback;
import com.parse.ParseException;
import com.parse.parsedevday.R;
import com.parse.parsedevday.model.Favorites;
import com.parse.parsedevday.model.Talk;
import com.parse.parsedevday.model.TalkComparator;

import java.util.List;

/**
 * A fragment that just contains a list of talks. If the "favoritesOnly" boolean argument is
 * included and set to true, then the list of talks will be filtered to only show those which have
 * been favorited, plus the ones marked as "alwaysFavorite", such as meals.
 */
public class IBeaconListFragment extends Fragment {

    public IBeaconListFragment() {
    }

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_ibeacon_list, container, false);

        ListView listView = (ListView) view.findViewById(R.id.list_view_ib);
        ArrayAdapter adapter = new ArrayAdapter(getActivity(), android.R.layout.simple_list_item_1);
        listView.setAdapter(adapter);

        List<IBeacon> iBeacons = IBeaconManager.getInstance().getIBeacons();
        for (IBeacon iBeacon : iBeacons) {
            adapter.add("Name: " + iBeacon.getName() + "\nAddress: " + iBeacon.getAddress() + "\nRSSI: " + iBeacon.getRssi() + "dBm");
            android.util.Log.w("test", "Name: " + iBeacon.getName() + "\nAddress: " + iBeacon.getAddress() + "\nRSSI: " + iBeacon.getRssi() + "dBm");
            adapter.notifyDataSetChanged();
        }

        android.util.Log.w("test", "IBEACON LIST FRAGMENT");

        return view;

    }

}