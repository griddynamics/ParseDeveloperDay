package com.parse.parsedevday.view;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import android.widget.ArrayAdapter;
import com.ibeacons.beaconinterface.IBeacon;
import com.ibeacons.lightbluebean.IBeaconManager;
import com.parse.FindCallback;
import com.parse.ParseException;
import com.parse.parsedevday.R;
import com.parse.parsedevday.model.Favorites;
import com.parse.parsedevday.model.Room;
import com.parse.parsedevday.model.Talk;
import com.parse.parsedevday.model.TalkComparator;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;
import android.widget.Toast;

/**
 * A fragment that just contains a list of talks. If the "favoritesOnly" boolean argument is
 * included and set to true, then the list of talks will be filtered to only show those which have
 * been favorited, plus the ones marked as "alwaysFavorite", such as meals.
 */
public class TalkListFragment extends Fragment implements Favorites.Listener {
    private TalkListAdapter adapter = null;

    // Whether or not to show only favorites.
    private boolean favoritesOnly = false;
    private boolean nearbyRoomsOnly = false;

    public TalkListFragment() {
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        final View view = inflater.inflate(R.layout.fragment_talk_list, container, false);

        favoritesOnly = false;
        nearbyRoomsOnly = false;

        Bundle args = getArguments();
        if (args != null) {
            favoritesOnly = args.getBoolean("favoritesOnly");
            nearbyRoomsOnly = args.getBoolean("nearbyRoomsOnly");
        }

        adapter = new TalkListAdapter(getActivity());
        final ListView list = (ListView) view.findViewById(R.id.list_view);
        list.setAdapter(adapter);

        // Fetch the list of all talks from Parse or the query cache.
        Talk.findInBackground(new FindCallback<Talk>() {
            @Override
            public void done(List<Talk> talks, ParseException e) {
                // When the set of favorites changes, update this UI.
                Favorites.get().addListener(TalkListFragment.this);

                if (e != null) {
                    Toast toast = Toast.makeText(getActivity(), e.getMessage(), Toast.LENGTH_LONG);
                    toast.show();
                    return;
                }

                if (talks == null) {
                    throw new RuntimeException("Somehow the list of talks was null.");
                }
        
        /*
         * Add all of the talks to the adapter, skipping any that weren't favorited, if
         * favoritesOnly is true.
         */
                if (nearbyRoomsOnly) {
                    Set<Talk> talksInRoomsWithFoundIBeacons = getTalksByFoundIBeacons(talks);
                    adapter.addAll(talksInRoomsWithFoundIBeacons);

                    setOnEmptyBeaconsListView();
                } else {
                    for (Talk talk : talks) {
                        if (!favoritesOnly || talk.isAlwaysFavorite() || Favorites.get().contains(talk)) {

                            android.util.Log.w("test", "Talk object id: " + talk.getObjectId() + "\nRoom name: "
                                    + talk.getRoom().getName() + "\nMAC addresses: " + (List) talk.getRoom().getIBeaconMacAddresses());
                            adapter.add(talk);
                        }
                    }
                }
            }

            private Set<Talk> getTalksByFoundIBeacons(List<Talk> talks) {
                List<String> iBeaconsAddresses = IBeaconManager.getInstance().getIBeaconsAddresses();
                Set<Talk> talksInRoomsWithFoundIBeacons = new LinkedHashSet<Talk>();
                for (String iBeaconAddress : iBeaconsAddresses) {
                    for (Talk talk : talks) {
                        List<String> roomIBeaconAddresses = (List)talk.getRoom().getIBeaconMacAddresses();
                        if (roomIBeaconAddresses != null && roomIBeaconAddresses.contains(iBeaconAddress)) {

                            android.util.Log.w("test", "Talk object id: " + talk.getObjectId() + "\nRoom name: "
                                    + talk.getRoom().getName() + "\nMAC addresses: " + roomIBeaconAddresses );
                            talksInRoomsWithFoundIBeacons.add(talk);
                        }
                    }
                }
                return talksInRoomsWithFoundIBeacons;
            }

            private void setOnEmptyBeaconsListView() {
                View emptyTextView = view.findViewById(R.id.empty);
                list.setEmptyView(emptyTextView);
            }

        });

        // If the user clicks on a talk, show the details activity with its info.
        list.setOnItemClickListener(new OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                Talk talk = adapter.getItem(position);
                Intent intent = new Intent(getActivity(), TalkActivity.class);
                intent.setData(talk.getUri());
                startActivity(intent);
            }
        });

        return view;
    }

    @Override
    public void onDestroyView() {
        Favorites.get().removeListener(this);
        super.onDestroyView();
        android.util.Log.w("test", "ONDESTROY TALKLISTFRAGMENT");
    }

    @Override
    public void onFavoriteAdded(Talk talk) {
        // If a new talk becomes favorited, automatically add it to this list.
        if (adapter != null) {
            if (favoritesOnly) {
                adapter.add(talk);
                adapter.sort(TalkComparator.get());
            }
            adapter.notifyDataSetChanged();
        }
    }

    @Override
    public void onFavoriteRemoved(Talk talk) {
        if (adapter != null) {
            if (favoritesOnly) {
                // This is commented out because we don't want favorites to disappear immediately.
                // adapter.remove(talk);
            } else {
                adapter.notifyDataSetChanged();
            }
        }
    }

    /**
     * Removes any talks from the list that haven't been favorited, if favoritesOnly is true.
     */
    public void removeUnfavoritedItems() {
        if (!favoritesOnly) {
            return;
        }
        for (int i = 0; adapter != null && i < adapter.getCount(); ++i) {
            Talk talk = adapter.getItem(i);
            if (!talk.isAlwaysFavorite() && !Favorites.get().contains(talk)) {
                adapter.remove(talk);
                i--;
            }
        }
    }


}