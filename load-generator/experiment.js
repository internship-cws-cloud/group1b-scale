import http from 'k6/http';
import { check, sleep } from 'k6';

const VUS = Number(__ENV.VUS || 20);
const DURATION = __ENV.DURATION || '5m';

export const options = {
    vus: VUS,
    duration: DURATION,

    thresholds: {
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(95)<800'],
    },
};

export default function () {
    const target = __ENV.TARGET;

    if (!target) {
        throw new Error('TARGET is required');
    }

    const url = `${target.replace(/\/+$/, '')}/api/tasks`;

    const response = http.get(url);

    check(response, {
        'status is 200': (r) => r.status === 200,
    });

    sleep(1);
}