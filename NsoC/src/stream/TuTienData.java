/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package stream;

import assembly.Char;
import assembly.Map;
import java.util.ArrayList;
import server.Manager;
import template.MapTemplate;

/**
 *
 * @author Administrator
 */
public class TuTienData {

    public static TuTienData tuTien = null;
    public static boolean tuTien50 = false;
    public static boolean tuTien100 = false;
    public static boolean finish;
    public static boolean start;
    public ArrayList<Char> ninjas = new ArrayList();
    public Map[] map;
    public long time;
    public int level = 0;
    public boolean rest;
    public Object LOCK = new Object();
    Server server;

    public TuTienData() {
        this.server = Server.gI();
        this.map = new Map[1];
        this.rest = false;
        this.initMap();
        for (byte i = 0; i < this.map.length; ++i) {
            this.map[i].timeMap = this.time;
            this.map[i].start();
        }

    }

    private void initMap() {
        if (MapTemplate.arrTemplate == null
                || MapTemplate.arrTemplate.length <= 192
                || MapTemplate.arrTemplate[192] == null) {
            this.map = new Map[0];
            TuTienData.tuTien = null;
            TuTienData.start = false;
            System.out.println("[TuTien] Bo qua su kien: chua co du lieu map 192 trong SQL.");
            return;
        }
        this.map[0] = new Map(192, null, null, null, null, null, null, this);
    }

    public void rest() {
        if (!this.rest) {
            this.rest = true;
            try {
                synchronized (this) {
                    Map ma;
                    Char _char;
                    while (this.ninjas.size() > 0) {
                        _char = this.ninjas.get(0);
                        if (_char != null) {
                            _char.tileMap.leave(_char.p);
                            _char.p.restCave();
                            ma = Manager.getMapid(_char.mapLTD);
                            byte k;
                            for (k = 0; k < ma.area.length; ++k) {
                                if (ma.area[k].numplayers < ma.template.maxplayers) {
                                    ma.area[k].EnterMap0(_char);
                                    break;
                                }
                            }
                        }
                    }
                }
                byte i;
                for (i = 0; i < this.map.length; ++i) {
                    this.map[i].close();
                    this.map[i] = null;
                }
                TuTienData.tuTien = null;

            } catch (Exception e) {
                byte i;
                for (i = 0; i < this.map.length; ++i) {
                    if (this.map[i] != null) {
                        this.map[i].close();
                        this.map[i] = null;
                    }
                }
                TuTienData.tuTien = null;
            }
        }
    }

    public void finish() {
        synchronized (this) {
            if (!TuTienData.finish) {
                TuTienData.finish = true;
                TuTienData.start = false;
                this.rest();
            }
        }
    }

}
