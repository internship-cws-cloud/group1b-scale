
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '1m', target: 20 },
        { duration: '3m', target: 60 },
        { duration: '1m', target: 0 },
    ],

    thresholds: {
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(95)<800'],
    },
};

export default function () {
    const url = __ENV.TARGET;

    const res = http.get(`${url}/api/tasks`);

    check(res, {
        'status 200': (r) => r.status === 200,
    });

    sleep(1);
}
