package com.example.devicestatus.model;

import jakarta.persistence.*;

// Added comment to demo automatic builds
@Entity
@Table(name = "devicestatuses")
public class DeviceStatus {

    @Id
    @Column(name = "deviceid", nullable = false)
    private Integer deviceId;

    @Column(name = "configfilesstatus", nullable = true, length = 255)
    private String configFilesStatus;

    @Column(name = "applicationsstatus", nullable = true, length = 255)
    private String applicationsStatus;

    public DeviceStatus() {}

    public DeviceStatus(Integer deviceId, String configFilesStatus, String applicationsStatus) {
        this.deviceId = deviceId;
        this.configFilesStatus = configFilesStatus;
        this.applicationsStatus = applicationsStatus;
    }

    public Integer getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(Integer deviceId) {
        this.deviceId = deviceId;
    }

    public String getConfigFilesStatus() {
        return configFilesStatus;
    }

    public void setConfigFilesStatus(String configFilesStatus) {
        this.configFilesStatus = configFilesStatus;
    }

    public String getApplicationsStatus() {
        return applicationsStatus;
    }

    public void setApplicationsStatus(String applicationsStatus) {
        this.applicationsStatus = applicationsStatus;
    }
}
