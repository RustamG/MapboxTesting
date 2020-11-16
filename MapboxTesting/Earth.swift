import CoreLocation
import Foundation

private let earthRadiusKm = 6371.0
private let earthRadiusMeters = earthRadiusKm * 1000

extension CLLocationCoordinate2D {

    func getLocationRelativeToTrack(startingAtPoint startPoint: CLLocationCoordinate2D,
                                    endPoint: CLLocationCoordinate2D
    ) -> LocationRelativeToTrack {

        let trackAngleFromY = (startPoint.bearingInRadians(to: endPoint) + 2 * Double.pi).truncatingRemainder(dividingBy: 2 * Double.pi)

        let crossTrackMeters = crossTrackErrorFromInMeters(startPoint: startPoint, and: endPoint)
        let info = LocationRelativeToTrack.Info(
            trackLength: startPoint.distanceInNM(to: endPoint) * 1852,
            trackAngleRad: trackAngleFromY,
            trackAngleDegrees: trackAngleFromY * 180.0 / Double.pi,
            crossTrackMeters: crossTrackMeters
        )

        let answer: LocationRelativeToTrack

        if crossTrackMeters > 0 {
            answer = .left(info)
        } else if crossTrackMeters < 0 {
            answer = .right(info)
        } else {
            answer = .onLine(info)
        }

        return answer
    }

    func bearingInRadians(to point: CLLocationCoordinate2D) -> Double {

        let lat1 = degreesToRadians(latitude)
        let lon1 = degreesToRadians(longitude)

        let lat2 = degreesToRadians(point.latitude)
        let lon2 = degreesToRadians(point.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return radiansBearing
    }

//    func crossTrackFromLineMeters(between startPoint: CLLocationCoordinate2D, and endPoint: CLLocationCoordinate2D) -> Double {
//
//        let lat1: Double = startPoint.latitude
//        let lon1: Double = startPoint.longitude
//        let lat2: Double = self.latitude
//        let lon2: Double = self.longitude
//        let lat3: Double = endPoint.latitude
//        let lon3: Double = endPoint.longitude
//
//        let y = sin(lon3 - lon1) * cos(lat3)
//        let x = cos(lat1) * sin(lat3) - sin(lat1) * cos(lat3) * cos(lat3 - lat1)
//        var bearing1: Double = radiansToDegrees(atan2(y, x))
//        bearing1 = 360 - (bearing1 + 360.0).truncatingRemainder(dividingBy: 360.0)
//
//        let y2 = sin(lon2 - lon1) * cos(lat2)
//        let x2 = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lat2 - lat1)
//        var bearing2 = radiansToDegrees(atan2(y2, x2))
//        bearing2 = 360 - (bearing2 + 360).truncatingRemainder(dividingBy: 360.0)
//
//        let lat1Rads = degreesToRadians(lat1)
//        let lat3Rads = degreesToRadians(lat3)
//        let dLon = degreesToRadians(lon3 - lon1)
//
//        let distanceAC = acos(sin(lat1Rads) * sin(lat3Rads) + cos(lat1Rads) * cos(lat3Rads) * cos(dLon)) * earthRadiusMeters
//        let minDistanceMeters = fabs(asin(sin(distanceAC/earthRadiusMeters) * sin(degreesToRadians(bearing1)
//                                                                            - degreesToRadians(bearing2))) * earthRadiusMeters)
//
//        return minDistanceMeters
//    }

    func crossTrackErrorFromInMeters(startPoint A: CLLocationCoordinate2D, and B: CLLocationCoordinate2D) -> Double {

        // Taken from http://www.edwilliams.org/avform.htm#XTE

        //        XTD =asin(sin(dist_AD)*sin(crs_AD-crs_AB))
        //        (positive XTD means right of course, negative means left)
        //        (If the point A is the N. or S. Pole replace crs_AD-crs_AB with
        //        lon_D-lon_B or lon_B-lon_D, respectively.)

        let D = self
        let distAD = A.distanceInNM(to: D)
        let courseAD = A.course(to: D)
        let courseAB = A.course(to: B)

        return asin(sin(distAD)*sin(courseAD-courseAB)) * earthRadiusMeters
    }

    private func distanceInNM(to: CLLocationCoordinate2D) -> Double {

        // Taken from http://www.edwilliams.org/avform.htm#Dist
        // The great circle distance d between two points with coordinates {lat1,lon1} and {lat2,lon2} is given by:
        //        d=acos(sin(lat1)*sin(lat2)+cos(lat1)*cos(lat2)*cos(lon1-lon2))
        //        A mathematically equivalent formula, which is less subject to rounding error for short distances is:
        //
        //        d=2*asin(sqrt((sin((lat1-lat2)/2))^2 +
        //                         cos(lat1)*cos(lat2)*(sin((lon1-lon2)/2))^2))

        let lat1 = degreesToRadians(latitude)
        let lon1 = degreesToRadians(longitude)
        let lat2 = degreesToRadians(to.latitude)
        let lon2 = degreesToRadians(to.longitude)

        return 2 * asin(sqrt(pow(sin((lat1-lat2)/2), 2) +
                                 pow(cos(lat1) * cos(lat2) * (sin((lon1-lon2)/2)), 2)))
    }

    private func course(to: CLLocationCoordinate2D) -> Double {

        // Taken from http://www.edwilliams.org/avform.htm#Crs

        let lat1 = degreesToRadians(latitude)
        let lon1 = degreesToRadians(longitude)
        let lat2 = degreesToRadians(to.latitude)
        let lon2 = degreesToRadians(to.longitude)

        // special case when starting point is a pole
        if cos(lat1) < 0.00000000001  {
            if lat1 > 0 {
                return Double.pi
            } else {
                return 2 * Double.pi
            }
        }

        // for starting points other than the poles
        let d = distanceInNM(to: to)

        if sin(lon2 - lon1) < 0 {
            return acos((sin(lat2)-sin(lat1)*cos(d))/(sin(d)*cos(lat1)))
        } else {
            return 2*Double.pi-acos((sin(lat2)-sin(lat1)*cos(d))/(sin(d)*cos(lat1)))
        }
    }

    private func degreesToRadians(_ degrees: Double) -> Double {

        return Double.pi * degrees / 180.0
    }

    private func radiansToDegrees(_ radians: Double) -> Double {

        return radians * 180.0 / Double.pi
    }
}
